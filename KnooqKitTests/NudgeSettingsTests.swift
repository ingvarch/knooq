import Testing
import Foundation
@testable import KnooqKit

@Suite struct NudgeSettingsTests {

    private func tempSettings() -> NudgeSettings {
        NudgeSettings(defaults: UserDefaults(suiteName: "nudge-\(UUID().uuidString)")!)
    }

    @Test func defaults() {
        let s = tempSettings()
        #expect(s.enabled == true)
        #expect(s.staleDays == 7)
        #expect(s.minGroupSize == 3)
    }

    @Test func persistsChanges() {
        let defaults = UserDefaults(suiteName: "nudge-\(UUID().uuidString)")!
        let s = NudgeSettings(defaults: defaults)
        s.enabled = false
        s.staleDays = 14
        s.minGroupSize = 5
        let reloaded = NudgeSettings(defaults: defaults)
        #expect(reloaded.enabled == false)
        #expect(reloaded.staleDays == 14)
        #expect(reloaded.minGroupSize == 5)
    }
}
