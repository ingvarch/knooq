import Testing
@testable import KnooqKit

@Test func sharedIdentifiersDefined() {
    #expect(KnooqShared.appGroupID == "group.app.knooq.ios")
    #expect(KnooqShared.cloudKitContainerID == "iCloud.app.knooq.ios")
}
