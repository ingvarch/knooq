import SwiftUI
import UIKit

/// Shown when Apple Intelligence isn't available. Explains why and routes to Settings.
/// Re-checks automatically when the app returns to the foreground.
struct AvailabilityGateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Knooq needs Apple Intelligence")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("Knooq re-checks automatically when you come back.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
    }
}

#Preview {
    AvailabilityGateView(message: "Apple Intelligence is turned off. Turn it on in Settings so Knooq can organize what you save.")
}
