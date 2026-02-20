import AppKit
import UserNotifications
import ServiceManagement

// MARK: - Settings Window Controller

class SettingsWindowController: NSWindowController {
    private var notifDot: NSTextField?
    private var notifLabel: NSTextField?
    private var notifButton: NSButton?
    private var hookButton: NSButton?
    private var hookDot: NSTextField?
    private var hookStatusLabel: NSTextField?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 390),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Shrimpy Settings"
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)
        window.contentView = buildContentView()
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        refreshNotificationStatus()
        refreshHookStatus()
    }

    private func buildContentView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 390))

        // App running status row
        let appDot = NSTextField(labelWithString: "●")
        appDot.textColor = NSColor.systemGreen
        appDot.font = NSFont.systemFont(ofSize: 14)
        appDot.frame = NSRect(x: 20, y: 346, width: 20, height: 20)
        view.addSubview(appDot)

        let appLabel = NSTextField(labelWithString: "Shrimpy is running")
        appLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        appLabel.frame = NSRect(x: 44, y: 346, width: 280, height: 20)
        view.addSubview(appLabel)

        // Notification permission row
        let dot = NSTextField(labelWithString: "●")
        dot.font = NSFont.systemFont(ofSize: 14)
        dot.frame = NSRect(x: 20, y: 316, width: 20, height: 20)
        view.addSubview(dot)
        notifDot = dot

        let notifLbl = NSTextField(labelWithString: "Notifications: checking…")
        notifLbl.font = NSFont.systemFont(ofSize: 13)
        notifLbl.frame = NSRect(x: 44, y: 316, width: 180, height: 20)
        view.addSubview(notifLbl)
        notifLabel = notifLbl

        let notifBtn = NSButton(title: "", target: self, action: #selector(notifButtonTapped))
        notifBtn.bezelStyle = .rounded
        notifBtn.font = NSFont.systemFont(ofSize: 12)
        notifBtn.frame = NSRect(x: 234, y: 312, width: 106, height: 26)
        notifBtn.isHidden = true
        view.addSubview(notifBtn)
        notifButton = notifBtn

        // Claude hook status row
        let hDot = NSTextField(labelWithString: "●")
        hDot.font = NSFont.systemFont(ofSize: 14)
        hDot.frame = NSRect(x: 20, y: 286, width: 20, height: 20)
        view.addSubview(hDot)
        hookDot = hDot

        let hLabel = NSTextField(labelWithString: "Claude hook: checking…")
        hLabel.font = NSFont.systemFont(ofSize: 13)
        hLabel.frame = NSRect(x: 44, y: 286, width: 280, height: 20)
        view.addSubview(hLabel)
        hookStatusLabel = hLabel

        // Separator
        let separator = NSBox()
        separator.boxType = .separator
        separator.frame = NSRect(x: 20, y: 268, width: 320, height: 1)
        view.addSubview(separator)

        // Sound label + picker
        let soundLabel = NSTextField(labelWithString: "Notification Sound:")
        soundLabel.font = NSFont.systemFont(ofSize: 13)
        soundLabel.frame = NSRect(x: 20, y: 230, width: 140, height: 20)
        view.addSubview(soundLabel)

        let sounds = ["Glass", "Tink", "Ping", "Pop", "Purr", "Basso", "Blow", "Bottle", "Frog", "Funk", "Hero", "Morse", "Sosumi", "Submarine"]
        let picker = NSPopUpButton(frame: NSRect(x: 165, y: 226, width: 175, height: 26))
        picker.addItems(withTitles: sounds)
        let currentSound = UserDefaults.standard.string(forKey: kSoundKey) ?? "Glass"
        picker.selectItem(withTitle: currentSound)
        picker.target = self
        picker.action = #selector(soundChanged(_:))
        view.addSubview(picker)

        // Launch at Login checkbox
        if #available(macOS 13.0, *) {
            let checkbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginToggled(_:)))
            checkbox.frame = NSRect(x: 20, y: 190, width: 260, height: 20)
            checkbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
            view.addSubview(checkbox)
        }

        // Test button
        let testButton = NSButton(title: "Test Notification", target: self, action: #selector(testTapped))
        testButton.bezelStyle = .rounded
        testButton.frame = NSRect(x: 20, y: 150, width: 160, height: 28)
        view.addSubview(testButton)

        // History button
        let historyButton = NSButton(title: "Notification History…", target: self, action: #selector(historyTapped))
        historyButton.bezelStyle = .rounded
        historyButton.frame = NSRect(x: 20, y: 110, width: 200, height: 28)
        view.addSubview(historyButton)

        // Configure Claude Hook button
        let hookBtn = NSButton(title: "Configure Claude Hook", target: self, action: #selector(configureTapped))
        hookBtn.bezelStyle = .rounded
        hookBtn.font = NSFont.systemFont(ofSize: 13)
        hookBtn.frame = NSRect(x: 20, y: 72, width: 200, height: 28)
        view.addSubview(hookBtn)
        hookButton = hookBtn

        // Info text
        let info = NSTextField(wrappingLabelWithString: "Hook invocations post to this running instance. Launch once via 'open /Applications/Shrimpy.app' and it persists in your menubar.")
        info.font = NSFont.systemFont(ofSize: 11)
        info.textColor = NSColor.tertiaryLabelColor
        info.frame = NSRect(x: 20, y: 8, width: 320, height: 58)
        view.addSubview(info)

        return view
    }

    func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async { self?.applyNotifStatus(settings.authorizationStatus) }
        }
    }

    func refreshHookStatus() {
        let installed = isHookInstalled()
        hookDot?.textColor = installed ? .systemGreen : .systemOrange
        hookStatusLabel?.stringValue = installed ? "Claude hook: Configured" : "Claude hook: Not configured"
    }

    private func applyNotifStatus(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized:
            notifDot?.textColor = .systemGreen
            notifLabel?.stringValue = "Notifications: Allowed"
            notifButton?.isHidden = true
        default:
            notifDot?.textColor = .systemOrange
            notifLabel?.stringValue = "Notifications: Not allowed"
            notifButton?.title = "Open Settings"
            notifButton?.isHidden = false
        }
    }

    @objc func notifButtonTapped() {
        // Register the app with the notification system, then send user to System Settings
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.refreshNotificationStatus() }
        }
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
    }

    @objc func soundChanged(_ sender: NSPopUpButton) {
        guard let selected = sender.selectedItem?.title else { return }
        UserDefaults.standard.set(selected, forKey: kSoundKey)
        if let d = NSApp.delegate as? AppDelegate {
            d.notificationManager.playSound(named: selected)
        }
    }

    @objc func launchAtLoginToggled(_ sender: NSButton) {
        if #available(macOS 13.0, *) {
            do {
                if sender.state == .on {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                sender.state = sender.state == .on ? .off : .on
            }
        }
    }

    @objc func testTapped() {
        if let d = NSApp.delegate as? AppDelegate {
            d.sendNotification(message: "This is a test notification")
        }
    }

    @objc func historyTapped() {
        if let d = NSApp.delegate as? AppDelegate {
            d.openHistory()
        }
    }

    @objc func configureTapped() {
        ensureClaudeNotificationHookInstalled()
        refreshHookStatus()
        hookButton?.title = "✓ Done"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.hookButton?.title = "Configure Claude Hook"
        }
    }
}
