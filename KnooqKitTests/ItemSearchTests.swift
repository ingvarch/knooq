import Testing
@testable import KnooqKit

@MainActor
@Suite struct ItemSearchTests {

    private func item(title: String? = nil, summary: String? = nil, note: String? = nil, tags: [String] = []) -> SavedItem {
        let item = SavedItem(rawType: .text)
        item.title = title
        item.summary = summary
        item.note = note
        item.tags = tags
        return item
    }

    @Test func matchesTitleCaseInsensitively() {
        #expect(ItemSearch.matches(item(title: "Swift Concurrency"), query: "swift"))
    }

    @Test func matchesSummaryNoteAndTags() {
        #expect(ItemSearch.matches(item(summary: "About actors"), query: "actor"))
        #expect(ItemSearch.matches(item(note: "buy milk"), query: "milk"))
        #expect(ItemSearch.matches(item(tags: ["ios", "ai"]), query: "AI"))
    }

    @Test func emptyQueryMatchesNothing() {
        #expect(!ItemSearch.matches(item(title: "anything"), query: "   "))
    }

    @Test func noMatchReturnsFalse() {
        #expect(!ItemSearch.matches(item(title: "Recipes"), query: "rust"))
    }

    @Test func searchFiltersList() {
        let items = [item(title: "Swift"), item(title: "Rust"), item(tags: ["swiftui"])]
        #expect(ItemSearch.search(items, query: "swift").count == 2)
    }
}
