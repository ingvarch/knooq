import SwiftUI
import SwiftData
import KnooqKit

/// Tag chip with tri-state: off (neutral), include (active/tinted), exclude (struck through).
struct TagChipButton: View {
    let label: String
    let state: Bool?   // nil = off, true = include, false = exclude
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .strikethrough(state == false)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(state == true ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary), in: Capsule())
                .foregroundStyle(state == true ? AnyShapeStyle(.white) : (state == false ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary)))
        }
        .buttonStyle(.plain)
    }
}

/// Browse items by tags with tri-state selection (include / exclude / off) and an "All Tags" mode.
struct TagFilterView: View {
    let initial: TagSelection

    @Query(filter: #Predicate<SavedItem> { !$0.isArchived },
           sort: \SavedItem.createdAt, order: .reverse)
    private var all: [SavedItem]

    @State private var selection: TagSelection

    init(initial: TagSelection) {
        self.initial = initial
        _selection = State(initialValue: initial)
    }

    private var processed: [SavedItem] { all.filter { $0.status == .processed } }
    private var allTags: [String] { ItemFilter.allTags(processed) }
    private var results: [SavedItem] { TagFiltering.filter(processed, selection: selection) }

    var body: some View {
        List {
            Section {
                FlowLayout(spacing: 8) {
                    TagChipButton(label: "All Tags", state: selection.allTags) {
                        TagFiltering.cycleAllTags(&selection)
                    }
                    ForEach(allTags, id: \.self) { tag in
                        TagChipButton(label: "#\(tag)", state: selection.states[tag]) {
                            TagFiltering.cycle(&selection, tag: tag)
                        }
                    }
                }
            }

            Section("\(results.count) \(results.count == 1 ? "article" : "articles")") {
                ForEach(results) { item in
                    NavigationLink(value: item) { ItemCardView(item: item) }
                }
            }
        }
        .navigationTitle(TagFiltering.title(selection))
        .navigationBarTitleDisplayMode(.inline)
    }
}
