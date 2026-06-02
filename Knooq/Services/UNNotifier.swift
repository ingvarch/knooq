import UserNotifications
import KnooqKit

/// Real `Notifier` backed by UserNotifications. Delivers nudges immediately (trigger: nil).
final class UNNotifier: Notifier {
    func schedule(_ notification: NudgeNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = "\(notification.category.rawValue) items need attention"
        content.body = notification.message
        content.sound = .default
        content.userInfo = ["category": notification.category.rawValue]

        let request = UNNotificationRequest(
            identifier: "nudge-\(notification.category.rawValue)",
            content: content,
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// One-time permission prompt; safe to call on every launch.
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}
