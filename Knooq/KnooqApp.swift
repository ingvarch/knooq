import SwiftUI
import SwiftData
import UserNotifications
import KnooqKit

@main
struct KnooqApp: App {
    private let container: ModelContainer
    private let processor: ItemProcessor
    private let nudgeScheduler: NudgeScheduler

    init() {
        let container = KnooqStore.resilientContainer()
        self.container = container
        self.processor = ItemProcessor(
            analyzer: FMAnalyzer(),
            extractor: CompositeTextExtractor()
        )
        self.nudgeScheduler = NudgeScheduler(container: container)
        nudgeScheduler.registerBackgroundTask()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await onAppLaunch() }
        }
        .modelContainer(container)
    }

    private func onAppLaunch() async {
        _ = await UNNotifier.requestAuthorization()
        await processPendingItems()
        await nudgeScheduler.runNudgeCheck()
        nudgeScheduler.scheduleBackgroundTask()
    }

    @MainActor
    private func processPendingItems() async {
        let context = container.mainContext
        // processAll only touches .pending items, so fetching all is sufficient (inbox is small).
        guard let items = try? context.fetch(FetchDescriptor<SavedItem>()) else { return }
        await processor.processAll(items)
        try? context.save()
    }
}

struct ContentView: View {
    var body: some View {
        InboxView()
    }
}
