import Testing
import Foundation
@testable import KnooqKit

@Suite struct CategoryTests {

    @Test func validatedKnownReturnsMatch() {
        #expect(ItemCategory.validated("Article") == .article)
        #expect(ItemCategory.validated("Tool") == .tool)
    }

    @Test func validatedUnknownFallsBackToOther() {
        #expect(ItemCategory.validated("Unknown") == .other)
        #expect(ItemCategory.validated("") == .other)
        #expect(ItemCategory.validated("article") == .other) // case-sensitive raw value
    }

    @Test func allCasesCoverFixedSet() {
        #expect(ItemCategory.allCases.count == 8)
        #expect(ItemCategory.allCases.map(\.rawValue) == [
            "Article", "Video", "Recipe", "Purchase",
            "Travel", "Idea", "Tool", "Other",
        ])
    }
}

@Suite struct EnumCodableTests {

    @Test func itemStatusRoundTrips() throws {
        for status in [ItemStatus.pending, .processed, .failed] {
            let data = try JSONEncoder().encode(status)
            #expect(try JSONDecoder().decode(ItemStatus.self, from: data) == status)
        }
    }

    @Test func rawTypeRoundTrips() throws {
        for type in [RawType.url, .image, .text] {
            let data = try JSONEncoder().encode(type)
            #expect(try JSONDecoder().decode(RawType.self, from: data) == type)
        }
    }
}

@Suite struct SavedItemTests {

    @Test func initSetsExpectedDefaults() {
        let item = SavedItem(rawType: .text, rawText: "hello")
        #expect(item.status == .pending)
        #expect(item.tags.isEmpty)
        #expect(item.isArchived == false)
        #expect(item.rawType == .text)
        #expect(item.rawText == "hello")
        #expect(item.category == nil)
        #expect(item.lastNudgedAt == nil)
        #expect(item.openedAt == nil)
    }

    @Test func storesAnalysisResults() {
        let item = SavedItem(rawType: .url, rawURL: URL(string: "https://example.com"))
        item.category = .article
        item.tags = ["swift", "ios"]
        item.title = "Title"
        item.summary = "Summary."
        item.status = .processed
        #expect(item.category == .article)
        #expect(item.tags == ["swift", "ios"])
        #expect(item.status == .processed)
    }
}
