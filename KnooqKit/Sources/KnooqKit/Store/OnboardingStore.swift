import Foundation

/// Persists onboarding state: whether it was completed and which extra languages the user
/// wants translated (BCP-47 codes). Backed by UserDefaults (injectable for tests).
public struct OnboardingStore {
    private let defaults: UserDefaults
    private enum Key {
        static let completed = "knooq.onboarding.completed"
        static let languages = "knooq.onboarding.languages"
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.completed) }
        set { defaults.set(newValue, forKey: Key.completed) }
    }

    public var translationLanguageCodes: [String] {
        get { defaults.stringArray(forKey: Key.languages) ?? [] }
        set { defaults.set(newValue, forKey: Key.languages) }
    }

    public mutating func complete(languageCodes: [String]) {
        translationLanguageCodes = languageCodes
        hasCompletedOnboarding = true
    }
}
