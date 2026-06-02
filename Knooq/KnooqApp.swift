import SwiftUI
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
        if services.isModelReady {
            InboxView()
        } else {
            AvailabilityGateView(message: services.modelMessage)
        }
    }
}
