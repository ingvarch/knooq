import BackgroundTasks
import SwiftData
import KnooqKit

/// Registers the daily BGAppRefreshTask and runs the nudge pass (also called on every launch,
/// since background scheduling is best-effort). Glue around the pure `NudgeRunner`.
@MainActor
final class NudgeScheduler {
    static let taskIdentifier = "app.knooq.ios.nudge-check"

    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            Task { @MainActor in self.handle(task as! BGAppRefreshTask) }
        }
    }

    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 24, to: .now)
        try? BGTaskScheduler.shared.submit(request)
    }

    /// Fetch all items, run one nudge pass with the user's settings, persist stamps.
    func runNudgeCheck() async {
        let settings = NudgeSettings()
        guard settings.enabled else {
            knooqLog("NudgeScheduler: reminders disabled, skipping")
            return
        }
        let engine = NudgeEngine(staleDays: settings.staleDays, minGroupSize: settings.minGroupSize)
        let runner = NudgeRunner(engine: engine, notifier: UNNotifier())

        let context = container.mainContext
        guard let items = try? context.fetch(FetchDescriptor<SavedItem>()) else { return }
        await runner.run(items: items)
        try? context.save()
    }

    private func handle(_ task: BGAppRefreshTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        Task { @MainActor in
            await runNudgeCheck()
            task.setTaskCompleted(success: true)
            scheduleBackgroundTask()
        }
    }
}
