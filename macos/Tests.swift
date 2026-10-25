import Foundation

@main
struct TrainingConfigTests {
    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    static func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
        if try !condition() { throw Failure(description: message) }
    }

    static func expectConfigError(_ message: String, _ action: () throws -> Void) throws {
        do {
            try action()
        } catch is TrainingConfig.ConfigError {
            return
        }
        throw Failure(description: message)
    }

    static func read(_ url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    static func write(_ text: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    static func main() throws {
        let fm = FileManager.default
        let temporary = fm.temporaryDirectory.appendingPathComponent("training-zoom-tests-\(UUID().uuidString)")
        try fm.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temporary) }

        let libraries = #"""
        "libraryfolders" {
            "0" { "path" "/Volumes/External SSD/SteamLibrary" }
            "1" { "path" "/Volumes/Quote \"Drive\"/SteamLibrary" }
            "2" { "path" "C:\\Games\\Steam" }
            "3" { "label" "not a library path" }
        }
        """#
        try expect(TrainingConfig.libraryPaths(in: libraries) == [
            "/Volumes/External SSD/SteamLibrary",
            "/Volumes/Quote \"Drive\"/SteamLibrary",
            #"C:\Games\Steam"#
        ], "Steam library paths must preserve spaces and decode escaped quotes and backslashes")

        let root = temporary.appendingPathComponent("dota 2 beta")
        let game = root.appendingPathComponent("game")
        try write("fixture", to: game.appendingPathComponent("dota/gameinfo.gi"))
        try expectConfigError("A Windows-only or incomplete install must be rejected") {
            _ = try TrainingConfig.validatedGameDirectory(root)
        }
        try write("fixture", to: game.appendingPathComponent("dota/bin/osx64/libclient.dylib"))
        let canonicalGame = game.standardizedFileURL.resolvingSymlinksInPath()
        try expect(TrainingConfig.validatedGameDirectory(root) == canonicalGame, "The install root must resolve to game")
        try expect(TrainingConfig.validatedGameDirectory(game) == canonicalGame, "The game folder must be accepted directly")

        let cfg = game.appendingPathComponent("dota/cfg")
        let zoom = cfg.appendingPathComponent("mac_training_zoom.cfg")
        let keys = cfg.appendingPathComponent("mac_training_zoom_keys.cfg")
        let autoexec = cfg.appendingPathComponent("autoexec.cfg")
        let userConfig = cfg.appendingPathComponent("user.cfg")
        let originalAutoexec = "bind F6 say_hello\n"
        let originalUser = "volume 0.3\n"
        try write(originalAutoexec, to: autoexec)
        try write(originalUser, to: userConfig)

        for invalid in [TrainingConfig.minDistance - 1, TrainingConfig.maxDistance + 1] {
            try expectConfigError("Installation must reject out-of-range distance \(invalid)") {
                try TrainingConfig.install(in: game, distance: invalid)
            }
        }
        try expect(!fm.fileExists(atPath: zoom.path) && !fm.fileExists(atPath: keys.path), "Invalid installs must not create either config")

        try TrainingConfig.install(in: root, distance: 1600)
        let zoomText = try read(zoom)
        let keyText = try read(keys)
        let commands = (zoomText + keyText).split(separator: "\n").map {
            $0.trimmingCharacters(in: .whitespaces)
        }.filter { !$0.isEmpty && !$0.hasPrefix("//") }
        try expect(zoomText.contains("\ndota_camera_distance 1600\n"), "The saved distance must be written")
        try expect(!commands.contains { $0.contains("sv_cheats") || $0.contains("autoexec") }, "Generated commands must not enable cheats or load autoexec")
        try expect(Set(try fm.contentsOfDirectory(atPath: cfg.path)) == Set([
            "autoexec.cfg", "user.cfg", "mac_training_zoom.cfg", "mac_training_zoom_keys.cfg"
        ]), "Installation must write only the two dedicated config files")

        for distance in [TrainingConfig.minDistance, TrainingConfig.maxDistance] {
            try TrainingConfig.writeDistance(distance, in: game)
            try expect(read(zoom).contains("\ndota_camera_distance \(distance)\n"), "Both distance bounds must be saved")
        }
        let savedZoom = try read(zoom)
        try expectConfigError("Updating an invalid distance must fail") {
            try TrainingConfig.writeDistance(2001, in: game)
        }
        try expect(read(zoom) == savedZoom, "A rejected update must preserve the saved distance")
        try expect(read(keys) == keyText, "Updating distance must preserve key settings")

        // A conflict in the second file must not modify the first file.
        let foreignKeys = "bind F7 custom_command\n"
        try write(foreignKeys, to: keys)
        try expectConfigError("Installation must reject an unowned keys file") {
            try TrainingConfig.install(in: game, distance: 1500)
        }
        try expect(read(zoom) == savedZoom && read(keys) == foreignKeys, "Both ownership checks must precede writes")

        let foreignZoom = "echo user-owned zoom file\n"
        try write(keyText, to: keys)
        try write(foreignZoom, to: zoom)
        try expectConfigError("Installation must reject an unowned zoom file") {
            try TrainingConfig.install(in: game, distance: 1500)
        }
        try expectConfigError("Updating must reject an unowned zoom file") {
            try TrainingConfig.writeDistance(1500, in: game)
        }
        try expect(read(zoom) == foreignZoom && read(keys) == keyText, "Unowned files and their companion file must remain untouched")
        try expect(read(autoexec) == originalAutoexec && read(userConfig) == originalUser, "Existing user configuration must remain untouched")
        print("TrainingConfig tests passed")
    }
}
