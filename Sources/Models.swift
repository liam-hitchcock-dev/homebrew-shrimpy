import Foundation

// MARK: - Models

struct NotificationHistoryEntry: Codable {
    let message: String
    let title: String
    let timestamp: Date
}
