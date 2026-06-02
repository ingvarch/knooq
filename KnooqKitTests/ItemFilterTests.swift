import Testing
@testable import KnooqKit

@MainActor
@Suite struct ItemFilterTests {

    private func item(_ category: ItemCategory?, tags: [String] = []) -> SavedItem {
        let item = SavedItem(rawType: .text)
        item.category = category
        item.tags = tags
        return item
    }

    @Test func noFiltersReturnsAll() {
        let items = [item(.idea), item(.tool)]
        #expect(ItemFilter.apply(items, category: nil, tag: nil).count == 2)
    }

    @Test func filtersByCategory() {
        let items = [item(.idea), item(.tool), item(.idea)]
        let out = ItemFilter.apply(items, category: .idea, tag: nil)
        #expect(out.count == 2)
        #expect(out.allSatisfy { $0.category == .idea })
    }

    @Test func filtersByTag() {
        let items = [item(.idea, tags: ["swift"]), item(.idea, tags: ["ios"])]
        let out = ItemFilter.apply(items, category: nil, tag: "swift")
        #expect(out.count == 1)
    }

    @Test func filtersByCategoryAndTag() {
        let items = [item(.idea, tags: ["swift"]), item(.tool, tags: ["swift"]), item(.idea, tags: ["ios"])]
        let out = ItemFilter.apply(items, category: .idea, tag: "swift")
        #expect(out.count == 1)
    }

    @Test func allTagsAreUniqueAndSorted() {
        let items = [item(.idea, tags: ["b", "a"]), item(.tool, tags: ["a", "c"])]
        #expect(ItemFilter.allTags(items) == ["a", "b", "c"])
    }
}
