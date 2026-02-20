import AppKit
import Darwin

// MARK: - Entry Point

let args = CommandLine.arguments

func acquireInstanceLock() -> Int32? {
    let fd = open(kInstanceLockPath, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
    guard fd != -1 else { return nil }
    if flock(fd, LOCK_EX | LOCK_NB) == 0 {
        return fd
    }
    close(fd)
    return nil
}

// Single-instance guard: use a lock file so duplicate launches from either
// app bundle or raw binary path cannot create a second menubar icon.
let instanceLockFD = acquireInstanceLock()

// Fallback bundle check kept for compatibility with older versions.
let runningApps = NSWorkspace.shared.runningApplications
let alreadyRunningByBundleID = runningApps.contains {
    $0.bundleIdentifier == kBundleID && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
}
let alreadyRunning = (instanceLockFD == nil) || alreadyRunningByBundleID

if args.count > 1 {
    let message = args[1]
    var customTitle: String?
    let terminalBundleID = detectTerminalBundleID()

    // Parse --title flag
    var i = 2
    while i < args.count {
        if args[i] == "--title" && i + 1 < args.count {
            customTitle = args[i + 1]
            i += 2
        } else {
            i += 1
        }
    }

    if alreadyRunning {
        var userInfo: [String: String] = [kNotificationMessageKey: message]
        if let title = customTitle { userInfo[kNotificationTitleKey] = title }
        if let tBundleID = terminalBundleID { userInfo[kTerminalBundleIDKey] = tBundleID }

        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name(kNotificationName),
            object: nil,
            userInfo: userInfo,
            deliverImmediately: true
        )
        exit(0)
    }
    // Not running yet — fall through and become the app, fire on launch
    AppDelegate.initialMessage = message
    AppDelegate.initialTitle = customTitle
    AppDelegate.initialTerminalBundleID = terminalBundleID
}

// If already running as menubar app with no message to send, just exit
if alreadyRunning { exit(0) }

// MARK: - App Startup

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
