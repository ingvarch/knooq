import Foundation
import SwiftData

/// Shared SwiftData container, backed by the App Group and synced via CloudKit.
/// App and Share Extension open the SAME store through this single factory (DRY).
public enum KnooqStore {

    public static func container(inMemory: Bool = false, appGroup: Bool = true, cloudKit: Bool = true) throws -> ModelContainer {
        let useGroup = !inMemory && appGroup
        let schema = Schema([SavedItem.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: useGroup ? .identifier(KnooqShared.appGroupID) : .none,
            cloudKitDatabase: (useGroup && cloudKit) ? .automatic : .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// True when the App Group entitlement is actually present (signed build).
    /// SwiftData hard-traps on a missing group container, so we must check before requesting one.
    private static var appGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: KnooqShared.appGroupID) != nil
    }

    /// Resilient open: App-Group + CloudKit when entitled, else a plain local store, else in-memory.
    /// Graceful degradation so the app still launches when iCloud/entitlements are unavailable.
    public static func resilientContainer() -> ModelContainer {
        if appGroupAvailable, let cloud = try? container() { return cloud }
        if let local = try? container(appGroup: false, cloudKit: false) { return local }
        return try! container(inMemory: true)
    }
}
