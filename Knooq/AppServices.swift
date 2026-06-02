import Foundation
import SwiftData
import KnooqKit

/// Owns the container + pipeline and runs the launch/foreground refresh.
/// Reentrancy-guarded so overlapping `.task` and scenePhase triggers can't run concurrently
/// (which would race the processor and its extractors).
@MainActor
final class AppServices {
    let container: ModelContainer
    private let processor: ItemProcessor
    private let nudgeScheduler: NudgeScheduler
    private var isRefreshing = false
    private var didRequestPermission = false

    init() {
        let container = KnooqStore.resilientContainer()
        self.container = container
        self.processor = ItemProcessor(analyzer: FMAnalyzer(), extractor: CompositeTextExtractor())
        self.nudgeScheduler = NudgeScheduler(container: container)
        nudgeScheduler.registerBackgroundTask()
    }

    func onLaunch() async {
        if !didRequestPermission {
            didRequestPermission = true
            _ = await UNNotifier.requestAuthorization()
        }
        await refresh()
        nudgeScheduler.scheduleBackgroundTask()
    }

    /// Import Share-Extension captures, process pending items, run the nudge check.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        importCaptures()
        await processPendingItems()
        await nudgeScheduler.runNudgeCheck()
    }

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

    private func processPendingItems() async {
        let context = container.mainContext
        guard let items = try? context.fetch(FetchDescriptor<SavedItem>()) else { return }
        // Retry items that failed on a previous run (captured before this pass, so we don't
        // immediately re-retry anything that fails right now — that waits for the next refresh).
        let previouslyFailed = items.filter { $0.status == .failed }
        await processor.processAll(items)
        await processor.retryFailed(previouslyFailed)
        try? context.save()
    }
}
