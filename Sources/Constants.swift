import Foundation

// MARK: - Constants

let kNotificationName = "com.shrimpy.notify"
let kNotificationMessageKey = "message"
let kNotificationTitleKey = "title"
let kTerminalBundleIDKey = "terminalBundleID"
let kSuiteName = "com.shrimpy.notifier"
let kSoundKey = "notificationSound"
let kCategoryID = "SHRIMPY_NOTIFY"
let kActionOpen = "ACTION_OPEN"
let kClaudeSettingsRelativePath = ".claude/settings.json"
let kClaudeNotificationMatcher = "^(permission_prompt|idle_prompt)$"
let kNotificationHistoryKey = "notificationHistory"
let kBundleID = "com.shrimpy.notifier"
let kInstanceLockPath = "/tmp/com.shrimpy.notifier.lock"

let kTerminalBundleIDs: Set<String> = [
    "com.apple.Terminal",
    "com.googlecode.iterm2",
    "dev.warp.Warp-Stable",
    "com.microsoft.VSCode",
    "co.zeit.hyper",
    "net.kovidgoyal.kitty",
    "io.alacritty",
    "com.jetbrains.GoLand",
    "com.apple.dt.Xcode"
]
