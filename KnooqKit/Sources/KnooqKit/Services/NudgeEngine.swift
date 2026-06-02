import Foundation

/// A category group worth nudging. Holds the @Model items, so it is used on the main actor.
public struct NudgeCandidate {
    public let category: ItemCategory
    public let items: [SavedItem]

    public init(category: ItemCategory, items: [SavedItem]) {
        self.category = category
        self.items = items
    }
}

/// Pure selection logic for resurfacing stale items. Time comes from an injected
/// `DateProvider` so staleness/anti-spam are deterministic in tests.
public final class NudgeEngine: Sendable {
    private let dateProvider: DateProvider
    private let staleDays: Int
    private let minGroupSize: Int
    private let maxNudgesPerDay: Int

    public init(
        dateProvider: DateProvider = SystemDateProvider(),
        staleDays: Int = 7,
        minGroupSize: Int = 3,
        maxNudgesPerDay: Int = 1
    ) {
        self.dateProvider = dateProvider
        self.staleDays = staleDays
        self.minGroupSize = minGroupSize
        self.maxNudgesPerDay = maxNudgesPerDay
    }

    /// Eligible: processed, not archived, has a category, and never nudged or stale beyond `staleDays`.
    /// Grouped by category; groups of `minGroupSize`+ qualify, largest first.
    @MainActor
    public func findCandidates(_ items: [SavedItem]) -> [NudgeCandidate] {
        let staleThreshold = dateProvider.now.addingTimeInterval(Double(-staleDays) * 86_400)

        let eligible = items.filter { item in
            guard item.status == .processed, !item.isArchived, item.category != nil else { return false }
            guard let lastNudged = item.lastNudgedAt else { return true }
            return lastNudged < staleThreshold
        }

        return Dictionary(grouping: eligible) { $0.category! }
            .filter { $0.value.count >= minGroupSize }
            .map { NudgeCandidate(category: $0.key, items: $0.value) }
            .sorted { $0.items.count > $1.items.count }
    }

    /// Anti-spam cap: at most `maxNudgesPerDay` notifications.
    public func selectForNotification(_ candidates: [NudgeCandidate]) -> [NudgeCandidate] {
        Array(candidates.prefix(maxNudgesPerDay))
    }

    @MainActor
    public func stampNudged(_ items: [SavedItem]) {
        let now = dateProvider.now
        for item in items { item.lastNudgedAt = now }
    }
}

/// Deterministic fallback text when FM is unavailable.
public enum NudgeTextGenerator {
    public static func fallback(category: ItemCategory, count: Int) -> String {
        "You have \(count) \(category.rawValue.lowercased()) items waiting for your attention."
    }
}
