import Foundation
import SwiftData
import FoundationModels
import KnooqKit

/// Owns the container + pipeline and runs the launch/foreground refresh.
/// Reentrancy-guarded so overlapping `.task` and scenePhase triggers can't run concurrently.
/// Also tracks Apple Intelligence availability so the UI can gate on it.
@MainActor
@Observable
final class AppServices {
    let container: ModelContainer
    let translationBridge: TranslationBridge
    private let processor: ItemProcessor
    private let nudgeScheduler: NudgeScheduler
    private var isRefreshing = false
    private var didRequestPermission = false
    private var onboarding: OnboardingStore

    /// Apple Intelligence state for the UI gate.
    private(set) var isModelReady = false
    private(set) var modelMessage = ""

    /// Whether the user finished onboarding (language setup).
    private(set) var hasOnboarded = false

    init() {
        let container = KnooqStore.resilientContainer()
        let bridge = TranslationBridge()
        let store = OnboardingStore()

        // Translate only the languages the user set up; otherwise FM runs directly.
        let languages = Set(store.translationLanguageCodes)
        let analyzer: Analyzer = languages.isEmpty
            ? FMAnalyzer()
            : TranslatingAnalyzer(base: FMAnalyzer(), translator: bridge, translatableLanguages: languages)

        self.container = container
        self.translationBridge = bridge
        self.onboarding = store
        self.processor = ItemProcessor(analyzer: analyzer, extractor: CompositeTextExtractor())
        self.nudgeScheduler = NudgeScheduler(container: container)
        self.hasOnboarded = store.hasCompletedOnboarding

        nudgeScheduler.registerBackgroundTask()
        knooqLog("AppServices: init, translatable languages = \(languages.sorted())")
        checkAvailability()
    }

    func completeOnboarding(languageCodes: [String]) {
        onboarding.complete(languageCodes: languageCodes)
        hasOnboarded = true
    }

    func onLaunch() async {
        if !didRequestPermission {
            didRequestPermission = true
            _ = await UNNotifier.requestAuthorization()
        }
        await refresh()
        nudgeScheduler.scheduleBackgroundTask()
    }

    /// Re-check availability, import Share captures, process pending (only if the model is ready),
    /// run the nudge check.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        checkAvailability()
        knooqLog("AppServices: refresh, modelReady = \(isModelReady)")
        importCaptures()
        if isModelReady {
            await processPendingItems()
        }
        await nudgeScheduler.runNudgeCheck()
    }

    func checkAvailability() {
        switch SystemLanguageModel.default.availability {
        case .available:
            isModelReady = true
            modelMessage = ""
        case .unavailable(.appleIntelligenceNotEnabled):
            isModelReady = false
            modelMessage = "Apple Intelligence is turned off. Turn it on in Settings so Knooq can organize what you save."
        case .unavailable(.deviceNotEligible):
            isModelReady = false
            modelMessage = "This device doesn't support Apple Intelligence, which Knooq needs to work."
        case .unavailable(.modelNotReady):
            isModelReady = false
            modelMessage = "Apple Intelligence is getting ready (downloading the model). This can take a few minutes on Wi‑Fi."
        case .unavailable:
            isModelReady = false
            modelMessage = "Apple Intelligence is unavailable right now. Try again shortly."
        }
    }

    private func importCaptures() {
        let captures = (try? CaptureQueue.appGroup().drain()) ?? []
        guard !captures.isEmpty else { return }
        knooqLog("AppServices: importing \(captures.count) capture(s)")
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
            item.note = capture.note?.isEmpty == false ? capture.note : nil
            if let category = capture.category {
                item.category = category
                item.userCategorized = true
            }
            context.insert(item)
        }
        try? context.save()
    }

    private func processPendingItems() async {
        let context = container.mainContext
        guard let items = try? context.fetch(FetchDescriptor<SavedItem>()) else { return }
        let pending = items.filter { $0.status == .pending }.count
        let previouslyFailed = items.filter { $0.status == .failed }
        knooqLog("AppServices: processing \(pending) pending, retrying \(previouslyFailed.count) failed")
        await processor.processAll(items)
        await processor.retryFailed(previouslyFailed)
        try? context.save()
    }
}
