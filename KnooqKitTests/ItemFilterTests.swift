import Testing
@testable import KnooqKit

@MainActor
@Suite struct ItemFilterTests {

    private func item(_ category: String?, tags: [String] = []) -> SavedItem {
        let item = SavedItem(rawType: .text)
        item.category = category
        item.tags = tags
        return item
    }

    @Test func noFiltersReturnsAll() {
        let items = [item("Idea"), item("Tool")]
        #expect(ItemFilter.apply(items, category: nil, tag: nil).count == 2)
    }

    @Test func filtersByCategory() {
        let items = [item("Idea"), item("Tool"), item("Idea")]
        let out = ItemFilter.apply(items, category: "Idea", tag: nil)
        #expect(out.count == 2)
        #expect(out.allSatisfy { $0.category == "Idea" })
    }

    @Test func filtersByTag() {
        let items = [item("Idea", tags: ["swift"]), item("Idea", tags: ["ios"])]
        let out = ItemFilter.apply(items, category: nil, tag: "swift")
        #expect(out.count == 1)
    }

    @Test func filtersByCategoryAndTag() {
        let items = [item("Idea", tags: ["swift"]), item("Tool", tags: ["swift"]), item("Idea", tags: ["ios"])]
        let out = ItemFilter.apply(items, category: "Idea", tag: "swift")
        #expect(out.count == 1)
    }

    @Test func allTagsAreUniqueAndSorted() {
        let items = [item("Idea", tags: ["b", "a"]), item("Tool", tags: ["a", "c"])]
        #expect(ItemFilter.allTags(items) == ["a", "b", "c"])
    }
}
