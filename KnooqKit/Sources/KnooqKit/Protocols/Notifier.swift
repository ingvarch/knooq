import Foundation

/// A scheduled nudge for one category group.
public struct NudgeNotification: Sendable, Equatable {
    public let category: String
    public let itemCount: Int
    public let message: String

    public init(category: String, itemCount: Int, message: String) {
        self.category = category
        self.itemCount = itemCount
        self.message = message
    }
}

/// Schedules local notifications. Prod: UNNotifier; test: StubNotifier.
public protocol Notifier: Sendable {
    func schedule(_ notification: NudgeNotification) async throws
    func cancelAll() async
}
