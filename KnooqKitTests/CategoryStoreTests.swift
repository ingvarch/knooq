import Testing
import Foundation
@testable import KnooqKit

@Suite struct CategoryStoreTests {

    private func tempStore() -> CategoryStore {
        CategoryStore(defaults: UserDefaults(suiteName: "cat-\(UUID().uuidString)")!)
    }

    @Test func addsCustomFolder() {
        var store = tempStore()
        store.add("Work")
        #expect(store.customFolders == ["Work"])
    }

    @Test func addTrimsAndDedupesCaseInsensitively() {
        var store = tempStore()
        store.add("  Work ")
        store.add("work")
        #expect(store.customFolders == ["Work"])
    }

    @Test func cannotAddNotes() {
        var store = tempStore()
        store.add("Notes")
        #expect(store.customFolders.isEmpty)
    }

    @Test func removesFolder() {
        var store = tempStore()
        store.add("Work"); store.add("Ideas")
        store.remove("Work")
        #expect(store.customFolders == ["Ideas"])
    }

    @Test func allowedForAIIncludesNotesCustomAndSuggestions() {
        var store = tempStore()
        store.add("Work")
        let allowed = store.allowedForAI()
        #expect(allowed.first == "Notes")
        #expect(allowed.contains("Work"))
        #expect(allowed.contains("Article"))
        #expect(allowed.contains("Other"))
    }
}

@Suite struct FoldersTests {

    @Test func notesAlwaysFirst() {
        #expect(Folders.visible(custom: [], used: []) == ["Notes"])
    }

    @Test func includesCustomThenUsedExtras() {
        let folders = Folders.visible(custom: ["Work"], used: ["Article", "Work", "Notes"])
        #expect(folders == ["Notes", "Work", "Article"])  // Notes, custom, then sorted extras
    }

    @Test func usedBuiltInsAppear() {
        let folders = Folders.visible(custom: [], used: ["Tool", "Article"])
        #expect(folders == ["Notes", "Article", "Tool"])
    }
}
