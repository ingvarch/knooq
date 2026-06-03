import Testing
import Foundation
@testable import KnooqKit

@MainActor
@Suite struct DateGroupingTests {

    // Fixed "now" = 2026-06-15.
    private let now = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 15))!

    private func item(_ comps: DateComponents) -> SavedItem {
        SavedItem(createdAt: Calendar.current.date(from: comps)!, rawType: .text)
    }

    @Test func bucketsTodayYesterdayMonthYear() {
        let items = [
            item(DateComponents(year: 2026, month: 6, day: 15)),  // Today
            item(DateComponents(year: 2026, month: 6, day: 14)),  // Yesterday
            item(DateComponents(year: 2026, month: 5, day: 3)),   // May (this year)
            item(DateComponents(year: 2025, month: 2, day: 1)),   // 2025
            item(DateComponents(year: 2025, month: 9, day: 1)),   // 2025 (same year bucket)
        ]
        let groups = DateGrouping.group(items, dateFor: { $0.createdAt }, now: now, ascending: false)
        let titles = groups.map(\.title)
        #expect(titles == ["Today", "Yesterday", "May", "2025"])
        #expect(groups.last?.items.count == 2)  // both 2025 items lumped together
    }

    @Test func ascendingReversesOrder() {
        let items = [
            item(DateComponents(year: 2026, month: 6, day: 15)),
            item(DateComponents(year: 2025, month: 1, day: 1)),
        ]
        let groups = DateGrouping.group(items, dateFor: { $0.createdAt }, now: now, ascending: true)
        #expect(groups.map(\.title) == ["2025", "Today"])
    }
}
