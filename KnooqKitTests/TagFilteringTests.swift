import Testing
@testable import KnooqKit

@MainActor
@Suite struct TagFilteringTests {

    private func item(_ tags: [String]) -> SavedItem {
        let item = SavedItem(rawType: .text)
        item.tags = tags
        return item
    }

    private func makeItems() -> [SavedItem] {
        [item(["education"]), item(["history"]), item(["education", "history"]), item([])]
    }
    private var items: [SavedItem] { makeItems() }

    @Test func includeShowsMatching() {
        let out = TagFiltering.filter(items, selection: .includingTag("education"))
        #expect(out.count == 2)  // ["education"] and ["education","history"]
    }

    @Test func excludeHidesMatching() {
        let out = TagFiltering.filter(items, selection: TagSelection(states: ["education": false]))
        #expect(out.count == 2)  // ["history"] and []
    }

    @Test func includeUnionAcrossTags() {
        let out = TagFiltering.filter(items, selection: TagSelection(states: ["education": true, "history": true]))
        #expect(out.count == 3)  // any of the two tags
    }

    @Test func allTaggedAndUntagged() {
        #expect(TagFiltering.filter(items, selection: TagSelection(allTags: true)).count == 3)
        #expect(TagFiltering.filter(items, selection: TagSelection(allTags: false)).count == 1)
    }

    @Test func titles() {
        #expect(TagFiltering.title(.includingTag("education")) == "#education")
        #expect(TagFiltering.title(TagSelection(states: ["history": false])) == "Not #history")
        #expect(TagFiltering.title(TagSelection(states: ["a": true, "b": true])) == "2 Tags")
        #expect(TagFiltering.title(TagSelection(allTags: true)) == "All Tags")
        #expect(TagFiltering.title(TagSelection(allTags: false)) == "Untagged")
    }

    @Test func cycleTransitions() {
        var sel = TagSelection()
        TagFiltering.cycle(&sel, tag: "x")
        #expect(sel.states["x"] == true)       // include
        TagFiltering.cycle(&sel, tag: "x")
        #expect(sel.states["x"] == false)      // exclude
        TagFiltering.cycle(&sel, tag: "x")
        #expect(sel.states["x"] == nil)        // off
    }

    @Test func cycleAllTagsClearsTags() {
        var sel = TagSelection(states: ["x": true])
        TagFiltering.cycleAllTags(&sel)
        #expect(sel.allTags == true)
        #expect(sel.states.isEmpty)
    }
}
