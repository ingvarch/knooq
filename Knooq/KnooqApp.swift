import SwiftUI
import KnooqKit

@main
struct KnooqApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("Knooq")
            .font(.largeTitle)
    }
}
