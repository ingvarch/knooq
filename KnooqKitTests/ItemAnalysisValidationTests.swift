import Testing
@testable import KnooqKit

@Suite struct ItemAnalysisValidationTests {

    @Test func knownCategoryKept() {
        let a = ItemAnalysis.validated(rawCategory: "Recipe", rawTags: [], title: "t", summary: "s")
        #expect(a.category == .recipe)
    }

    @Test func unknownCategoryBecomesOther() {
        let a = ItemAnalysis.validated(rawCategory: "Nonsense", rawTags: [], title: "t", summary: "s")
        #expect(a.category == .other)
    }

    @Test func tagsLowercasedAndTrimmedToSix() {
        let a = ItemAnalysis.validated(
            rawCategory: "Idea",
            rawTags: ["One", "TWO", "Three", "four", "Five", "six", "seven", "eight"],
            title: "t", summary: "s"
        )
        #expect(a.tags.count == 6)
        #expect(a.tags == ["one", "two", "three", "four", "five", "six"])
    }

    @Test func keepsTitleAndSummary() {
        let a = ItemAnalysis.validated(rawCategory: "Tool", rawTags: ["x"], title: "Title", summary: "Sum.")
        #expect(a.title == "Title")
        #expect(a.summary == "Sum.")
    }
}
