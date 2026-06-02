import Foundation

/// Orchestrates a nudge pass: select qualifying groups, schedule notifications, stamp items.
/// Pure over injected `NudgeEngine` + `Notifier` — no BGTask, UserNotifications, or SwiftData here.
/// The app's scheduler fetches/saves items and supplies a real `Notifier`.
public final class NudgeRunner: Sendable {
    private let engine: NudgeEngine
    private let notifier: Notifier

    public init(engine: NudgeEngine, notifier: Notifier) {
        self.engine = engine
        self.notifier = notifier
    }

    /// Runs one pass over `items`; returns the number of notifications scheduled.
    @MainActor
    @discardableResult
    public func run(items: [SavedItem]) async -> Int {
        let selected = engine.selectForNotification(engine.findCandidates(items))
        for candidate in selected {
            let message = NudgeTextGenerator.fallback(category: candidate.category, count: candidate.items.count)
            try? await notifier.schedule(
                NudgeNotification(category: candidate.category, itemCount: candidate.items.count, message: message)
            )
            engine.stampNudged(candidate.items)
        }
        return selected.count
    }
}
