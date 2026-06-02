import SwiftUI
import KnooqKit

// Minimal read-only detail; task 12 adds manual category/tag editing and "open original".
struct ItemDetailView: View {
    let item: SavedItem

    var body: some View {
        List {
            if let category = item.category {
                CategoryChip(category: category)
            }
            if !item.tags.isEmpty {
                TagsRow(tags: item.tags)
            }
            if let summary = item.summary {
                Text(summary)
            }
        }
        .navigationTitle(item.title ?? "Untitled")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ItemDetailView(item: PreviewData.samples[0])
    }
}
#endif
