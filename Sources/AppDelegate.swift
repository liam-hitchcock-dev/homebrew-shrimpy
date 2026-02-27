import AppKit
import UserNotifications

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, NSMenuDelegate {
    static var initialMessage: String?
    static var initialTitle: String?
    static var initialTerminalBundleID: String?

    var statusItem: NSStatusItem?
    var settingsWindowController: SettingsWindowController?
    var historyWindowController: HistoryWindowController?

    var muteMenuItem: NSMenuItem?
    var goToConversationMenuItem: NSMenuItem?
    var conversationSeparatorItem: NSMenuItem?
    var lastTerminalBundleID: String?
    var hasPendingNotification = false

    let notificationManager = NotificationManager()

    // Convenience accessor for history so HistoryWindowController can clear it
    var notificationHistory: [NotificationHistoryEntry] {
        get { notificationManager.history }
        set { notificationManager.history = newValue }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupUNCenter()
        setupDistributedListener()
        ensureClaudeNotificationHookInstalled()

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateStatusIcon(pending: self.hasPendingNotification)
        }

        if let message = AppDelegate.initialMessage {
            lastTerminalBundleID = AppDelegate.initialTerminalBundleID
            sendNotification(message: message, title: AppDelegate.initialTitle)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Forwarding

    func sendNotification(message: String, title: String? = nil) {
        notificationManager.send(message: message, title: title)
        DispatchQueue.main.async { self.updateStatusIcon(pending: true) }
    }

    // MARK: - Status Item

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            if let url2x = Bundle.main.url(forResource: "ShrimpyBar@2x", withExtension: "png"),
               let image = NSImage(contentsOf: url2x) {
                image.size = NSSize(width: 22, height: 22)
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "🦐"
            }
        }

        let menu = NSMenu()

        let goToItem = NSMenuItem(
            title: "Go to Claude conversation",
            action: #selector(goToConversation),
            keyEquivalent: ""
        )
        goToItem.isHidden = true
        goToItem.target = self
        menu.addItem(goToItem)
        goToConversationMenuItem = goToItem

        let convSeparator = NSMenuItem.separator()
        convSeparator.isHidden = true
        menu.addItem(convSeparator)
        conversationSeparatorItem = convSeparator

        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))

        let muteItem = NSMenuItem(title: "Mute Notifications", action: #selector(toggleMute), keyEquivalent: "")
        menu.addItem(muteItem)
        muteMenuItem = muteItem

        menu.addItem(NSMenuItem(title: "Notification History", action: #selector(openHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) {
            item.target = self
        }

        menu.delegate = self
        statusItem?.menu = menu
    }

    // MARK: - Menu Bar Icon

    func updateStatusIcon(pending: Bool) {
        hasPendingNotification = pending
        guard let button = statusItem?.button else { return }

        guard let url2x = Bundle.main.url(forResource: "ShrimpyBar@2x", withExtension: "png"),
              let baseImage = NSImage(contentsOf: url2x) else {
            return
        }
        baseImage.size = NSSize(width: 22, height: 22)

        if !pending {
            baseImage.isTemplate = true
            button.image = baseImage
            return
        }

        let size = NSSize(width: 22, height: 22)
        let composite = NSImage(size: size)
        composite.lockFocus()

        let isDark = button.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        baseImage.isTemplate = false
        if isDark {
            // Draw white version by tinting the stencil
            NSColor.white.setFill()
        } else {
            NSColor.black.setFill()
        }
        baseImage.draw(in: NSRect(origin: .zero, size: size),
                       from: .zero,
                       operation: .sourceOver,
                       fraction: 1.0)

        let dotDiameter: CGFloat = 6
        let dotRect = NSRect(x: size.width - dotDiameter - 1,
                             y: size.height - dotDiameter - 1,
                             width: dotDiameter,
                             height: dotDiameter)
        NSColor.systemOrange.setFill()
        NSBezierPath(ovalIn: dotRect).fill()

        composite.unlockFocus()
        composite.isTemplate = false
        button.image = composite
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        let wasPending = hasPendingNotification
        goToConversationMenuItem?.isHidden = !wasPending
        conversationSeparatorItem?.isHidden = !wasPending
        updateStatusIcon(pending: false)
    }

    @objc func goToConversation() {
        focusTerminal()
    }

    @objc func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openHistory() {
        if historyWindowController == nil {
            historyWindowController = HistoryWindowController()
        }
        historyWindowController?.loadHistory(notificationManager.history)
        historyWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func toggleMute() {
        notificationManager.isMuted = !notificationManager.isMuted
        muteMenuItem?.title = notificationManager.isMuted ? "Unmute Notifications" : "Mute Notifications"
    }

    // MARK: - UNUserNotificationCenter

    func setupUNCenter() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let openAction = UNNotificationAction(
            identifier: kActionOpen,
            title: "Open Terminal",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: kCategoryID,
            actions: [openAction],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == kActionOpen ||
           response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            focusTerminal()
        }
        completionHandler()
    }

    func focusTerminal() {
        guard let bundleID = lastTerminalBundleID else { return }
        if let termApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) {
            if #available(macOS 14.0, *) {
                termApp.activate()
            } else {
                termApp.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }

    // MARK: - Distributed Notifications

    func setupDistributedListener() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(receivedDistributedNotification(_:)),
            name: NSNotification.Name(kNotificationName),
            object: nil
        )
    }

    @objc func receivedDistributedNotification(_ notification: NSNotification) {
        let message = (notification.userInfo?[kNotificationMessageKey] as? String) ?? "Needs your input"
        let title = notification.userInfo?[kNotificationTitleKey] as? String
        lastTerminalBundleID = notification.userInfo?[kTerminalBundleIDKey] as? String
        sendNotification(message: message, title: title)
    }
}
