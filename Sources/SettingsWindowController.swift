import AppKit
import UserNotifications
import ServiceManagement

// MARK: - Settings Window Controller

class SettingsWindowController: NSWindowController {
    private var hookButton: NSButton?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 160),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Shrimpy Settings"
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        refreshUI()
    }

    private func refreshUI() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self else { return }
                let notifOk = settings.authorizationStatus == .authorized
                let hookOk = isHookInstalled()
                self.buildUI(notifOk: notifOk, hookOk: hookOk)
            }
        }
    }

    private func buildUI(notifOk: Bool, hookOk: Bool) {
        let width: CGFloat = 300
        let pad: CGFloat = 20
        let gap: CGFloat = 12
        let rowH: CGFloat = 26

        let view = NSView()
        var y: CGFloat = pad

        // Test Notification button (bottom)
        let testBtn = NSButton(title: "Test Notification", target: self, action: #selector(testTapped))
        testBtn.bezelStyle = .rounded
        testBtn.frame = NSRect(x: pad, y: y, width: 140, height: rowH)
        view.addSubview(testBtn)
        y += rowH + gap

        // Launch at Login
        if #available(macOS 13.0, *) {
            let checkbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginToggled(_:)))
            checkbox.frame = NSRect(x: pad, y: y, width: 260, height: 20)
            checkbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
            view.addSubview(checkbox)
            y += 20 + gap
        }

        // Sound picker
        let soundLabel = NSTextField(labelWithString: "Notification Sound:")
        soundLabel.font = NSFont.systemFont(ofSize: 13)
        soundLabel.frame = NSRect(x: pad, y: y + 2, width: 130, height: 20)
        view.addSubview(soundLabel)

        let sounds = ["Glass", "Tink", "Ping", "Pop", "Purr", "Basso", "Blow", "Bottle", "Frog", "Funk", "Hero", "Morse", "Sosumi", "Submarine"]
        let picker = NSPopUpButton(frame: NSRect(x: pad + 135, y: y - 1, width: width - pad * 2 - 135, height: 26))
        picker.addItems(withTitles: sounds)
        let currentSound = UserDefaults.standard.string(forKey: kSoundKey) ?? "Glass"
        picker.selectItem(withTitle: currentSound)
        picker.target = self
        picker.action = #selector(soundChanged(_:))
        view.addSubview(picker)
        y += rowH + gap

        // Warning section (only shown when something needs attention)
        if !notifOk || !hookOk {
            let sep = NSBox()
            sep.boxType = .separator
            sep.frame = NSRect(x: pad, y: y, width: width - pad * 2, height: 1)
            view.addSubview(sep)
            y += 1 + gap

            if !hookOk {
                addWarningRow(to: view, at: &y, width: width, pad: pad, gap: gap,
                    text: "Claude hook not configured",
                    buttonTitle: "Configure",
                    action: #selector(configureTapped))
            }

            if !notifOk {
                addWarningRow(to: view, at: &y, width: width, pad: pad, gap: gap,
                    text: "Notifications not allowed",
                    buttonTitle: "Open Settings",
                    action: #selector(notifButtonTapped))
            }
        }

        y += pad - gap

        view.frame = NSRect(x: 0, y: 0, width: width, height: y)

        let oldFrame = window?.frame ?? .zero
        window?.setContentSize(NSSize(width: width, height: y))
        if oldFrame.width > 0 {
            var newFrame = window!.frame
            newFrame.origin.y = oldFrame.maxY - newFrame.height
            window?.setFrame(newFrame, display: true)
        }
        window?.contentView = view
    }

    private func addWarningRow(to view: NSView, at y: inout CGFloat, width: CGFloat, pad: CGFloat, gap: CGFloat,
                               text: String, buttonTitle: String, action: Selector) {
        let dot = NSTextField(labelWithString: "●")
        dot.textColor = .systemOrange
        dot.font = NSFont.systemFont(ofSize: 12)
        dot.frame = NSRect(x: pad, y: y, width: 16, height: 20)
        view.addSubview(dot)

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12)
        label.frame = NSRect(x: pad + 18, y: y, width: 160, height: 20)
        view.addSubview(label)

        let btn = NSButton(title: buttonTitle, target: self, action: action)
        btn.bezelStyle = .rounded
        btn.font = NSFont.systemFont(ofSize: 11)
        let btnWidth: CGFloat = buttonTitle == "Open Settings" ? 110 : 90
        btn.frame = NSRect(x: width - pad - btnWidth, y: y - 2, width: btnWidth, height: 24)
        view.addSubview(btn)

        if action == #selector(configureTapped) {
            hookButton = btn
        }

        y += 26 + gap
    }

    // MARK: - Actions

    @objc func notifButtonTapped() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] _, _ in
            DispatchQueue.main.async { self?.refreshUI() }
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

    @objc func configureTapped() {
        ensureClaudeNotificationHookInstalled()
        hookButton?.title = "Done"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.refreshUI()
        }
    }
}
