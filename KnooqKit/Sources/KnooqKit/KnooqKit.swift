// KnooqKit — shared model + domain logic (reuse core for app + extension).

import Foundation

/// Shared identifiers, defined once and consumed everywhere (DRY).
public enum KnooqShared {
    public static let appGroupID = "group.app.knooq.ios"
    public static let cloudKitContainerID = "iCloud.app.knooq.ios"

    /// App Group UserDefaults — shared between the app and the Share Extension. Falls back to
    /// standard if the suite is unavailable. Stores (categories, onboarding, settings) use this so
    /// both processes see the same data.
    public static var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }
}
