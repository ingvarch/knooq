import Foundation
import SwiftData

/// Shared SwiftData container, backed by the App Group and synced via CloudKit.
/// App and Share Extension open the SAME store through this single factory (DRY).
public enum KnooqStore {

    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([SavedItem.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier(KnooqShared.appGroupID),
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
