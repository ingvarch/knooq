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

    @Test func tagsLowercasedAndTrimmedToThree() {
        let a = ItemAnalysis.validated(
            rawCategory: "Idea",
            rawTags: ["One", "TWO", "Three", "four", "Five"],
            title: "t", summary: "s"
        )
        #expect(a.tags.count == 3)
        #expect(a.tags == ["one", "two", "three"])
    }

    @Test func keepsTitleAndSummary() {
        let a = ItemAnalysis.validated(rawCategory: "Tool", rawTags: ["x"], title: "Title", summary: "Sum.")
        #expect(a.title == "Title")
        #expect(a.summary == "Sum.")
    }
}
