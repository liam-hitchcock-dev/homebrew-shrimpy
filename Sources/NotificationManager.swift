import AppKit
import UserNotifications
import Foundation

// MARK: - Notification Manager

class NotificationManager {
    static let maxHistoryCount = 50

    var history: [NotificationHistoryEntry] {
        didSet { persistHistory() }
    }
    var isMuted: Bool = false

    init() {
        history = Self.loadHistory()
        if history.count > NotificationManager.maxHistoryCount {
            history = Array(history.prefix(NotificationManager.maxHistoryCount))
            persistHistory()
        }
    }

    func send(message: String, title: String? = nil) {
        guard !isMuted else { return }

        let soundName = UserDefaults.standard.string(forKey: kSoundKey) ?? "Glass"
        playSound(named: soundName)

        let resolvedTitle = title ?? "Shrimpy"
        let entry = NotificationHistoryEntry(message: message, title: resolvedTitle, timestamp: Date())
        history.insert(entry, at: 0)
        if history.count > NotificationManager.maxHistoryCount {
            history = Array(history.prefix(NotificationManager.maxHistoryCount))
        }

        let content = UNMutableNotificationContent()
        content.title = resolvedTitle
        content.body = message
        content.categoryIdentifier = kCategoryID

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("Shrimpy: failed to post notification: %@", error.localizedDescription)
            }
        }
    }

    func playSound(named soundName: String) {
        let path = "/System/Library/Sounds/\(soundName).aiff"
        if let sound = NSSound(contentsOfFile: path, byReference: false) {
            sound.play()
        }
    }

    private func persistHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            let url = Self.historyFileURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Shrimpy: failed to persist notification history: %@", error.localizedDescription)
        }
    }

    private static func loadHistory() -> [NotificationHistoryEntry] {
        let fileURL = historyFileURL()
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([NotificationHistoryEntry].self, from: data) {
            return decoded
        }

        // One-time fallback: read old defaults-backed history and migrate to file store.
        guard let data = UserDefaults.standard.data(forKey: kNotificationHistoryKey) else { return [] }
        do {
            let decoded = try JSONDecoder().decode([NotificationHistoryEntry].self, from: data)
            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? data.write(to: fileURL, options: .atomic)
            return decoded
        } catch {
            NSLog("Shrimpy: failed to load notification history: %@", error.localizedDescription)
            return []
        }
    }

    private static func historyFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Shrimpy", isDirectory: true)
            .appendingPathComponent("notification-history.json", isDirectory: false)
    }
}
