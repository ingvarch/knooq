import Testing
import Foundation
@testable import KnooqKit

@Suite struct CategoryTests {

    @Test func validatedKnownReturnsMatch() {
        let allowed = Categories.suggestions + ["Work"]
        #expect(Categories.validated("Article", allowed: allowed) == "Article")
        #expect(Categories.validated("Work", allowed: allowed) == "Work")
    }

    @Test func validatedIsCaseInsensitive() {
        #expect(Categories.validated("article", allowed: Categories.suggestions) == "Article")
    }

    @Test func validatedUnknownFallsBackToOther() {
        #expect(Categories.validated("Nonsense", allowed: Categories.suggestions) == "Other")
        #expect(Categories.validated("", allowed: Categories.suggestions) == "Other")
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
        item.category = "Article"
        item.tags = ["swift", "ios"]
        item.title = "Title"
        item.summary = "Summary."
        item.status = .processed
        #expect(item.category == "Article")
        #expect(item.tags == ["swift", "ios"])
        #expect(item.status == .processed)
    }
}
