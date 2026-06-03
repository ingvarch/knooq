import Testing
@testable import KnooqKit

@MainActor
@Suite struct SavedItemEditingTests {

    private func item() -> SavedItem { SavedItem(rawType: .text) }

    @Test func addTagNormalizesAndStamps() {
        let i = item()
        i.addTag("  Swift ")
        #expect(i.tags == ["swift"])
        #expect(i.openedAt != nil)
    }

    @Test func addTagDedupes() {
        let i = item()
        i.addTag("swift")
        i.addTag("SWIFT")
        #expect(i.tags == ["swift"])
    }

    @Test func addTagIgnoresEmpty() {
        let i = item()
        i.addTag("   ")
        #expect(i.tags.isEmpty)
        #expect(i.openedAt == nil)  // no-op did not stamp
    }

    @Test func removeTagRemovesAndStamps() {
        let i = item()
        i.tags = ["swift", "ios"]
        i.removeTag("swift")
        #expect(i.tags == ["ios"])
        #expect(i.openedAt != nil)
    }

    @Test func setCategoryStamps() {
        let i = item()
        i.setCategory("Tool")
        #expect(i.category == "Tool")
        #expect(i.openedAt != nil)
    }

    @Test func assignFolderRescuesFailedItem() {
        let i = item()
        i.status = .failed
        i.failureReason = "boom"
        i.assignFolder("Work")
        #expect(i.category == "Work")
        #expect(i.userCategorized == true)
        #expect(i.status == .processed)
        #expect(i.failureReason == nil)
    }

    @Test func assignFolderKeepsProcessedItemProcessed() {
        let i = item()
        i.status = .processed
        i.assignFolder("Work")
        #expect(i.status == .processed)
        #expect(i.category == "Work")
    }

    @Test func setNoteStoresAndStamps() {
        let i = item()
        i.setNote("  hello ")
        #expect(i.note == "hello")
        #expect(i.openedAt != nil)
    }

    @Test func setNoteEmptyClears() {
        let i = item()
        i.note = "x"
        i.setNote("   ")
        #expect(i.note == nil)
    }

    @Test func toggleArchiveFlips() {
        let i = item()
        #expect(i.isArchived == false)
        i.toggleArchive()
        #expect(i.isArchived == true)
        i.toggleArchive()
        #expect(i.isArchived == false)
    }
}
