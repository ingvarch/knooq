import Foundation

/// User-tunable reminder settings, persisted in UserDefaults (injectable for tests).
public struct NudgeSettings {
    private let defaults: UserDefaults
    private enum Key {
        static let enabled = "knooq.nudge.enabled"
        static let staleDays = "knooq.nudge.staleDays"
        static let minGroupSize = "knooq.nudge.minGroupSize"
    }

    public static let defaultStaleDays = 7
    public static let defaultMinGroupSize = 3

    public init(defaults: UserDefaults = KnooqShared.defaults) {
        self.defaults = defaults
    }

    /// Master switch for reminders. Defaults to on.
    public var enabled: Bool {
        get { defaults.object(forKey: Key.enabled) as? Bool ?? true }
        nonmutating set { defaults.set(newValue, forKey: Key.enabled) }
    }

    /// Days an item must sit before it can be nudged.
    public var staleDays: Int {
        get { let v = defaults.integer(forKey: Key.staleDays); return v == 0 ? Self.defaultStaleDays : v }
        nonmutating set { defaults.set(newValue, forKey: Key.staleDays) }
    }

    /// Minimum items in a category before it's worth a reminder.
    public var minGroupSize: Int {
        get { let v = defaults.integer(forKey: Key.minGroupSize); return v == 0 ? Self.defaultMinGroupSize : v }
        nonmutating set { defaults.set(newValue, forKey: Key.minGroupSize) }
    }
}
