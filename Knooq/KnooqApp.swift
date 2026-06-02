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

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await onAppLaunch() }
                .onChange(of: scenePhase) { _, phase in
                    // Re-import + process when returning to foreground (Share may have run while suspended).
                    if phase == .active { Task { await refresh() } }
                }
        }
        .modelContainer(container)
    }

    private func onAppLaunch() async {
        _ = await UNNotifier.requestAuthorization()
        await refresh()
        nudgeScheduler.scheduleBackgroundTask()
    }

    private func refresh() async {
        importCaptures()
        await processPendingItems()
        await nudgeScheduler.runNudgeCheck()
    }

    /// Drain raw captures written by the Share Extension into SwiftData as .pending items.
    @MainActor
    private func importCaptures() {
        let captures = (try? CaptureQueue.appGroup().drain()) ?? []
        guard !captures.isEmpty else { return }
        let context = container.mainContext
        for capture in captures {
            let item = SavedItem(
                createdAt: capture.createdAt,
                rawType: capture.rawType,
                rawURL: capture.urlString.flatMap(URL.init(string:)),
                rawText: capture.text,
                imageFilename: capture.imageFilename
            )
            item.title = CaptureTitle.provisional(rawType: capture.rawType, urlString: capture.urlString, text: capture.text)
            context.insert(item)
        }
        try? context.save()
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
