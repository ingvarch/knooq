import Testing
import Foundation
@testable import KnooqKit

@MainActor
@Suite struct NudgeEngineTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private func daysAgo(_ d: Int) -> Date { now.addingTimeInterval(Double(-d) * 86_400) }

    private func engine() -> NudgeEngine {
        NudgeEngine(dateProvider: StubDateProvider(now))
    }

    private func item(
        _ category: ItemCategory?,
        status: ItemStatus = .processed,
        archived: Bool = false,
        lastNudged: Date? = nil
    ) -> SavedItem {
        let item = SavedItem(rawType: .text)
        item.status = status
        item.category = category
        item.isArchived = archived
        item.lastNudgedAt = lastNudged
        return item
    }

    @Test func threeNeverNudgedSameCategoryIsCandidate() {
        let items = [item(.idea), item(.idea), item(.idea)]
        let candidates = engine().findCandidates(items)
        #expect(candidates.count == 1)
        #expect(candidates.first?.category == .idea)
        #expect(candidates.first?.items.count == 3)
    }

    @Test func twoItemsBelowThreshold() {
        let candidates = engine().findCandidates([item(.idea), item(.idea)])
        #expect(candidates.isEmpty)
    }

    @Test func nudgedSixDaysAgoExcluded() {
        let items = [item(.idea, lastNudged: daysAgo(6)),
                     item(.idea, lastNudged: daysAgo(6)),
                     item(.idea, lastNudged: daysAgo(6))]
        #expect(engine().findCandidates(items).isEmpty)
    }

    @Test func nudgedEightDaysAgoIsCandidate() {
        let items = [item(.idea, lastNudged: daysAgo(8)),
                     item(.idea, lastNudged: daysAgo(8)),
                     item(.idea, lastNudged: daysAgo(8))]
        #expect(engine().findCandidates(items).count == 1)
    }

    @Test func archivedExcluded() {
        let items = [item(.idea), item(.idea), item(.idea, archived: true)]
        #expect(engine().findCandidates(items).isEmpty)  // only 2 eligible
    }

    @Test func pendingAndFailedExcluded() {
        let items = [item(.idea), item(.idea, status: .pending), item(.idea, status: .failed)]
        #expect(engine().findCandidates(items).isEmpty)
    }

    @Test func nilCategoryExcluded() {
        let items = [item(nil), item(nil), item(nil)]
        #expect(engine().findCandidates(items).isEmpty)
    }

    @Test func largestGroupSortedFirst() {
        let items = [item(.idea), item(.idea), item(.idea),
                     item(.tool), item(.tool), item(.tool), item(.tool)]
        let candidates = engine().findCandidates(items)
        #expect(candidates.count == 2)
        #expect(candidates.first?.category == .tool)  // 4 > 3
    }

    @Test func antiSpamCapSelectsOne() {
        let groups = (0..<5).map {
            NudgeCandidate(category: ItemCategory.allCases[$0], items: [item(.idea), item(.idea), item(.idea)])
        }
        #expect(engine().selectForNotification(groups).count == 1)
    }

    @Test func stampNudgedSetsClockNow() {
        let items = [item(.idea), item(.idea)]
        engine().stampNudged(items)
        #expect(items.allSatisfy { $0.lastNudgedAt == now })
    }

    @Test func fallbackTextMentionsCountAndCategory() {
        let text = NudgeTextGenerator.fallback(category: .recipe, count: 3)
        #expect(text.contains("3"))
        #expect(text.contains("recipe"))
    }
}
