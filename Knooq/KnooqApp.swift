import SwiftUI
import Translation
import KnooqKit

@main
struct KnooqApp: App {
    @State private var services = AppServices()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(services: services)
                .task { await services.onLaunch() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await services.refresh() } }
                }
        }
        .modelContainer(services.container)
    }
}

struct ContentView: View {
    let services: AppServices

    var body: some View {
        content
            // Hosts the Translation session for the headless pipeline (see TranslationBridge).
            .translationTask(services.translationBridge.config) { session in
                await services.translationBridge.perform(session)
            }
    }

    @ViewBuilder
    private var content: some View {
        if !services.hasOnboarded {
            OnboardingView { codes in services.completeOnboarding(languageCodes: codes) }
        } else if services.isModelReady {
            InboxView()
        } else {
            AvailabilityGateView(message: services.modelMessage)
        }
    }
}
