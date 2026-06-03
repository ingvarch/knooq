import SwiftUI
import UIKit
import UserNotifications
import KnooqKit

/// Reminder (nudge) settings: master toggle, timing, threshold, and notification permission.
struct RemindersView: View {
    @State private var enabled = NudgeSettings().enabled
    @State private var staleDays = NudgeSettings().staleDays
    @State private var minGroupSize = NudgeSettings().minGroupSize
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            Section {
                Toggle("Reminders", isOn: $enabled)
                    .onChange(of: enabled) { _, value in NudgeSettings().enabled = value }
            } footer: {
                Text("Knooq nudges you about groups of saved items you haven't gotten back to.")
            }

            if enabled {
                Section("When to remind") {
                    Stepper("After \(staleDays) days", value: $staleDays, in: 1...60)
                        .onChange(of: staleDays) { _, value in NudgeSettings().staleDays = value }
                    Stepper("When \(minGroupSize)+ items pile up", value: $minGroupSize, in: 2...20)
                        .onChange(of: minGroupSize) { _, value in NudgeSettings().minGroupSize = value }
                }
            }

            Section("Notifications") {
                notificationRow
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshAuthStatus() }
    }

    @ViewBuilder
    private var notificationRow: some View {
        switch authStatus {
        case .authorized, .provisional, .ephemeral:
            Label("Notifications enabled", systemImage: "checkmark.circle")
                .foregroundStyle(.green)
        case .notDetermined:
            Button("Enable notifications") {
                Task {
                    _ = await UNNotifier.requestAuthorization()
                    await refreshAuthStatus()
                }
            }
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Text("Notifications are off in iOS Settings.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        @unknown default:
            EmptyView()
        }
    }

    private func refreshAuthStatus() async {
        authStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}
