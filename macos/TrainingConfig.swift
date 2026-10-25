import Foundation

enum TrainingConfig {
    static let minDistance = 1134
    static let maxDistance = 2000
    static let applyCommand = "exec mac_training_zoom"
    static let setupCommand = "exec mac_training_zoom_keys"
    static let marker = "// Dota Training Zoom for macOS"

    enum ConfigError: LocalizedError {
        case missingGame, invalidDistance, existingFile(String)

        var errorDescription: String? {
            switch self {
            case .missingGame:
                return "Не найдена Mac-версия Dota. Выбери папку dota 2 beta или её папку game."
            case .invalidDistance:
                return "Расстояние должно быть от 1134 до 2000."
            case .existingFile(let name):
                return "Файл \(name) уже существует и создан другой программой. Он не изменён."
            }
        }
    }

    static func command(for distance: Int) -> String {
        "dota_camera_distance \(max(minDistance, min(maxDistance, distance)))"
    }

    static func validatedGameDirectory(_ url: URL) throws -> URL {
        let root = url.standardizedFileURL.resolvingSymlinksInPath()
        let candidates = [root, root.appendingPathComponent("game")]
        for candidate in candidates {
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("dota/gameinfo.gi").path),
               FileManager.default.fileExists(atPath: candidate.appendingPathComponent("dota/bin/osx64/libclient.dylib").path) {
                return candidate
            }
        }
        throw ConfigError.missingGame
    }

    static func locateGameDirectory() -> URL? {
        let steam = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Steam")
        var libraries = [steam]
        if let text = try? String(contentsOf: steam.appendingPathComponent("steamapps/libraryfolders.vdf"), encoding: .utf8) {
            libraries += libraryPaths(in: text).map { URL(fileURLWithPath: $0, isDirectory: true) }
        }
        for library in libraries {
            if let game = try? validatedGameDirectory(library.appendingPathComponent("steamapps/common/dota 2 beta")) {
                return game
            }
        }
        return nil
    }

    static func libraryPaths(in text: String) -> [String] {
        let expression = try! NSRegularExpression(pattern: #""path"\s*"((?:\\.|[^"\\])*)""#)
        return expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
            guard let range = Range($0.range(at: 1), in: text) else { return nil }
            return String(text[range]).replacingOccurrences(of: #"\\"#, with: #"\"#)
                .replacingOccurrences(of: #"\""#, with: #"""#)
        }
    }

    static func install(in gameDirectory: URL, distance: Int) throws {
        let game = try validatedGameDirectory(gameDirectory)
        try validate(distance)
        let cfg = game.appendingPathComponent("dota/cfg", isDirectory: true)
        let zoom = cfg.appendingPathComponent("mac_training_zoom.cfg")
        let keys = cfg.appendingPathComponent("mac_training_zoom_keys.cfg")
        // Check both destinations before changing either file.
        try checkOwnership(zoom)
        try checkOwnership(keys)
        try FileManager.default.createDirectory(at: cfg, withIntermediateDirectories: true)
        try zoomContents(distance).write(to: zoom, atomically: true, encoding: .utf8)
        let keyContents = """
        \(marker)
        // Optional: executing this file REPLACES your F6/F7/F8 bindings.
        // This file is never loaded automatically. No sv_cheats changes.
        bind "F6" "dota_camera_distance 1200"
        bind "F7" "dota_camera_distance 2000"
        bind "F8" "exec mac_training_zoom"
        echo "Training zoom keys: F6 default (1200), F7 far (2000), F8 saved distance."

        """
        try keyContents.write(to: keys, atomically: true, encoding: .utf8)
    }

    static func writeDistance(_ distance: Int, in gameDirectory: URL) throws {
        let game = try validatedGameDirectory(gameDirectory)
        try validate(distance)
        let destination = game.appendingPathComponent("dota/cfg/mac_training_zoom.cfg")
        try checkOwnership(destination)
        try zoomContents(distance).write(to: destination, atomically: true, encoding: .utf8)
    }

    private static func validate(_ distance: Int) throws {
        guard (minDistance...maxDistance).contains(distance) else { throw ConfigError.invalidDistance }
    }

    private static func checkOwnership(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let text = try String(contentsOf: url, encoding: .utf8)
        guard text.hasPrefix(marker + "\n") else { throw ConfigError.existingFile(url.lastPathComponent) }
    }

    private static func zoomContents(_ distance: Int) -> String {
        """
        \(marker)
        // Hero Demo or a local cheat-enabled practice session.
        // The game enforces the cheat restriction; this file does not bypass it.
        \(command(for: distance))
        dota_camera_distance

        """
    }
}
