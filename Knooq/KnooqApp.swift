import SwiftUI
import KnooqKit

@main
struct KnooqApp: App {
    @State private var services = AppServices()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await services.onLaunch() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await services.refresh() } }
                }
        }
        .modelContainer(services.container)
    }
}

struct ContentView: View {
    var body: some View {
        InboxView()
    }
}
