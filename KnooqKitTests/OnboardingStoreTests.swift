import Testing
import Foundation
@testable import KnooqKit

@Suite struct OnboardingStoreTests {

    private func tempStore() -> OnboardingStore {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        return OnboardingStore(defaults: defaults)
    }

    @Test func defaultsToNotOnboarded() {
        let store = tempStore()
        #expect(store.hasCompletedOnboarding == false)
        #expect(store.translationLanguageCodes.isEmpty)
    }

    @Test func persistsCompletion() {
        var store = tempStore()
        store.complete(languageCodes: ["ru", "uk"])
        #expect(store.hasCompletedOnboarding == true)
        #expect(store.translationLanguageCodes == ["ru", "uk"])
    }

    @Test func sharesViaSameDefaults() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        var a = OnboardingStore(defaults: defaults)
        a.complete(languageCodes: ["es"])
        let b = OnboardingStore(defaults: defaults)
        #expect(b.hasCompletedOnboarding == true)
        #expect(b.translationLanguageCodes == ["es"])
    }
}
