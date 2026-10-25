import AppKit

@main
@MainActor
struct TrainingZoomApplication {
    static func main() {
        let application = NSApplication.shared
        let delegate = TrainingZoomDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}

@MainActor
final class TrainingZoomDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var gameDirectory: URL?
    private var selectedDistance = 1600
    private let distanceLabel = NSTextField(labelWithString: "1600")
    private let directoryLabel = NSTextField(wrappingLabelWithString: "Папка Dota 2 не найдена. Выберите её вручную.")
    private let statusLabel = NSTextField(wrappingLabelWithString: "Выберите расстояние и сохраните файлы, затем выполните команду в консоли Dota 2.")
    private let slider = NSSlider(value: 1600, minValue: Double(TrainingConfig.minDistance), maxValue: Double(TrainingConfig.maxDistance), target: nil, action: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        createMenu()
        createWindow()
        restoreDirectory()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func createMenu() {
        let menu = NSMenu()
        let applicationItem = NSMenuItem()
        let applicationMenu = NSMenu()
        applicationMenu.addItem(withTitle: "Завершить Training Zoom", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        applicationItem.submenu = applicationMenu
        menu.addItem(applicationItem)
        NSApp.mainMenu = menu
    }

    private func createWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 660, height: 600), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Dota 2 · Training Zoom"
        window.center()

        let content = window.contentView!
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -22)
        ])

        let title = label("Камера для тренировки", size: 23, weight: .semibold)
        add(title, to: stack)
        add(note("Для демо героя и локальной игры с ботами. В локальном лобби включите читы в настройках игры. Приложение не включает их само."), to: stack)
        addSeparator(to: stack)

        let folderRow = row([
            label("Папка Dota 2", size: 14, weight: .semibold),
            button("Выбрать папку…", action: #selector(chooseDirectory))
        ])
        add(folderRow, to: stack)
        directoryLabel.font = .systemFont(ofSize: 11)
        directoryLabel.textColor = .secondaryLabelColor
        directoryLabel.isSelectable = true
        directoryLabel.maximumNumberOfLines = 2
        add(directoryLabel, to: stack)
        addSeparator(to: stack)

        distanceLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .medium)
        add(row([label("Расстояние камеры", size: 14, weight: .semibold), distanceLabel]), to: stack)
        slider.target = self
        slider.action = #selector(distanceChanged)
        slider.isContinuous = true
        slider.setAccessibilityLabel("Расстояние камеры")
        add(slider, to: stack)

        let presets = [1200, 1600, 2000].map { value -> NSButton in
            let preset = button(String(value), action: #selector(selectPreset(_:)))
            preset.tag = value
            return preset
        }
        add(row(presets + [button("Сброс → 1200", action: #selector(resetDistance))]), to: stack)
        add(button("Установить / сохранить зум", action: #selector(saveDistance)), to: stack)
        add(note("Сохранение обновляет отдельные файлы настроек. Чтобы изменить камеру в игре, выполните команду применения в консоли или нажмите назначенную клавишу."), to: stack)
        addSeparator(to: stack)

        add(row([
            button("Копировать применение", action: #selector(copyApplyCommand)),
            button("Копировать текущее значение", action: #selector(copyDistanceCommand))
        ]), to: stack)
        add(note("Необязательно: F6 — обычный зум (1200), F7 — дальний (2000), F8 — сохранённый.\nКоманда настройки заменяет прежние действия этих клавиш.\nНазначения меняются только после выполнения команды в консоли."), to: stack)
        add(button("Копировать настройку F6/F7/F8", action: #selector(copySetupCommand)), to: stack)

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.isSelectable = true
        add(statusLabel, to: stack)
        statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight = .regular) -> NSTextField {
        let result = NSTextField(labelWithString: text)
        result.font = .systemFont(ofSize: size, weight: weight)
        return result
    }

    private func note(_ text: String) -> NSTextField {
        let result = NSTextField(wrappingLabelWithString: text)
        result.font = .systemFont(ofSize: 12)
        result.textColor = .secondaryLabelColor
        return result
    }

    private func button(_ title: String, action: Selector) -> NSButton {
        let result = NSButton(title: title, target: self, action: action)
        result.bezelStyle = .rounded
        return result
    }

    private func row(_ views: [NSView]) -> NSStackView {
        let result = NSStackView(views: views)
        result.orientation = .horizontal
        result.alignment = .centerY
        result.spacing = 12
        return result
    }

    private func add(_ view: NSView, to stack: NSStackView) {
        stack.addArrangedSubview(view)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        if view is NSTextField || view is NSSlider {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
    }

    private func addSeparator(to stack: NSStackView) {
        let separator = NSBox()
        separator.boxType = .separator
        stack.addArrangedSubview(separator)
        separator.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        stack.setCustomSpacing(14, after: separator)
    }

    private func restoreDirectory() {
        if let savedPath = UserDefaults.standard.string(forKey: "DotaGameDirectory"),
           let directory = try? TrainingConfig.validatedGameDirectory(URL(fileURLWithPath: savedPath)) {
            selectDirectory(directory)
        } else if let directory = TrainingConfig.locateGameDirectory() {
            selectDirectory(directory)
        }
    }

    private func selectDirectory(_ directory: URL) {
        gameDirectory = directory
        directoryLabel.stringValue = directory.path
        directoryLabel.toolTip = directory.path
        UserDefaults.standard.set(directory.path, forKey: "DotaGameDirectory")
    }

    @objc private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Выберите папку Dota 2"
        panel.message = "Выберите папку dota 2 beta или папку game внутри неё."
        panel.prompt = "Выбрать"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = gameDirectory
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            selectDirectory(try TrainingConfig.validatedGameDirectory(url))
            showStatus("Папка выбрана. Нажмите «Установить / сохранить зум», чтобы записать настройки.")
        } catch {
            showStatus(error.localizedDescription, isError: true)
        }
    }

    private func setDistance(_ value: Int) {
        selectedDistance = min(max(value, TrainingConfig.minDistance), TrainingConfig.maxDistance)
        slider.doubleValue = Double(selectedDistance)
        distanceLabel.stringValue = String(selectedDistance)
    }

    @objc private func distanceChanged() {
        setDistance(Int(slider.doubleValue.rounded()))
        showStatus("Выбрано \(selectedDistance). Сохраните значение или скопируйте прямую команду для консоли.")
    }

    @objc private func selectPreset(_ sender: NSButton) {
        setDistance(sender.tag)
        showStatus("Выбрано \(selectedDistance). Сохраните значение или скопируйте прямую команду для консоли.")
    }

    @objc private func resetDistance() {
        setDistance(1200)
        showStatus("Выбрано 1200. Изменение ещё не сохранено и не применено в игре.")
    }

    @objc private func saveDistance() {
        guard let directory = gameDirectory else {
            showStatus("Сначала выберите папку установленной Dota 2.", isError: true)
            return
        }
        do {
            try TrainingConfig.install(in: directory, distance: selectedDistance)
            showStatus("Файлы сохранены: \(selectedDistance). В консоли Dota 2 выполните: \(TrainingConfig.applyCommand). Камера ещё не изменена приложением.")
        } catch {
            showStatus(error.localizedDescription, isError: true)
        }
    }

    private func copy(_ command: String, message: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        showStatus("\(message)\n\(command)")
    }

    @objc private func copyApplyCommand() {
        copy(TrainingConfig.applyCommand, message: "Скопировано. После сохранения файлов вставьте команду в консоль Dota 2.")
    }

    @objc private func copyDistanceCommand() {
        copy(TrainingConfig.command(for: selectedDistance), message: "Скопировано. Вставьте команду в консоль тренировки, чтобы установить \(selectedDistance).")
    }

    @objc private func copySetupCommand() {
        copy(TrainingConfig.setupCommand, message: "Скопировано. Выполнение команды в консоли назначит F6/F7/F8, заменив их прежние действия.")
    }

    private func showStatus(_ message: String, isError: Bool = false) {
        statusLabel.stringValue = message
        statusLabel.textColor = isError ? .systemRed : .secondaryLabelColor
    }
}
