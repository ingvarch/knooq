import Testing
import Foundation
@testable import KnooqKit

@MainActor
@Suite struct NudgeRunnerTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func item(_ category: String) -> SavedItem {
        let item = SavedItem(rawType: .text)
        item.status = .processed
        item.category = category
        return item
    }

    private func runner(_ notifier: Notifier) -> NudgeRunner {
        NudgeRunner(engine: NudgeEngine(dateProvider: StubDateProvider(now)), notifier: notifier)
    }

    @Test func schedulesOneNotificationForQualifyingGroup() async {
        let notifier = StubNotifier()
        let items = [item("Idea"), item("Idea"), item("Idea")]
        let sent = await runner(notifier).run(items: items)
        #expect(sent == 1)
        #expect(notifier.scheduled.count == 1)
        #expect(notifier.scheduled.first?.category == "Idea")
        #expect(notifier.scheduled.first?.itemCount == 3)
    }

    @Test func stampsNudgedItems() async {
        let notifier = StubNotifier()
        let items = [item("Idea"), item("Idea"), item("Idea")]
        _ = await runner(notifier).run(items: items)
        #expect(items.allSatisfy { $0.lastNudgedAt == now })
    }

    @Test func antiSpamCapsToOneAcrossGroups() async {
        let notifier = StubNotifier()
        var items: [SavedItem] = []
        for c in ["Idea", "Tool", "Recipe"] {
            items += [item(c), item(c), item(c)]
        }
        let sent = await runner(notifier).run(items: items)
        #expect(sent == 1)
        #expect(notifier.scheduled.count == 1)
    }

    @Test func noCandidatesSchedulesNothing() async {
        let notifier = StubNotifier()
        let sent = await runner(notifier).run(items: [item("Idea"), item("Idea")])  // below threshold
        #expect(sent == 0)
        #expect(notifier.scheduled.isEmpty)
    }
}
