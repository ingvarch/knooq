import Testing
@testable import KnooqKit

@Suite struct ItemAnalysisValidationTests {

    private let allowed = Categories.suggestions + ["Work"]

    @Test func knownCategoryKept() {
        let a = ItemAnalysis.validated(rawCategory: "Recipe", allowed: allowed, rawTags: [], title: "t", summary: "s")
        #expect(a.category == "Recipe")
    }

    @Test func customCategoryKept() {
        let a = ItemAnalysis.validated(rawCategory: "Work", allowed: allowed, rawTags: [], title: "t", summary: "s")
        #expect(a.category == "Work")
    }

    @Test func unknownCategoryBecomesOther() {
        let a = ItemAnalysis.validated(rawCategory: "Nonsense", allowed: allowed, rawTags: [], title: "t", summary: "s")
        #expect(a.category == "Other")
    }

    @Test func tagsLowercasedAndTrimmedToThree() {
        let a = ItemAnalysis.validated(
            rawCategory: "Idea", allowed: allowed,
            rawTags: ["One", "TWO", "Three", "four", "Five"],
            title: "t", summary: "s"
        )
        #expect(a.tags == ["one", "two", "three"])
    }

    @Test func keepsTitleAndSummary() {
        let a = ItemAnalysis.validated(rawCategory: "Tool", allowed: allowed, rawTags: ["x"], title: "Title", summary: "Sum.")
        #expect(a.title == "Title")
        #expect(a.summary == "Sum.")
    }
}
