import SwiftUI
import SwiftData
import KnooqKit

private enum DetailEditor: String, Identifiable {
    case category, tags, description
    var id: String { rawValue }
}

struct ItemDetailView: View {
    @Bindable var item: SavedItem
    var onRetry: () async -> Void = {}

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var editor: DetailEditor?
    @State private var confirmingDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if item.status == .failed { failureCard }
                CategoryBadge(category: item.category)

                if let description = item.displayDescription {
                    section("Description") { Text(description).font(.body) }
                }

                if let url = item.rawURL {
                    Link(destination: url) {
                        Label("Open Original", systemImage: "safari").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    LinkPreview(url: url)
                }
                if let filename = item.imageFilename {
                    ImagePreview(filename: filename)
                }

                if !item.tags.isEmpty {
                    section("Tags") { TagsRow(tags: item.tags) }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { settingsMenu }
        }
        .sheet(item: $editor) { which in
            switch which {
            case .category: CategoryEditorSheet(item: item)
            case .tags: TagsEditorSheet(item: item)
            case .description: DescriptionEditorSheet(item: item)
            }
        }
        .alert("Delete this item?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                context.delete(item)
                dismiss()
            }
        } message: {
            Text("This can't be undone.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title ?? "Untitled").font(.title.bold())
            HStack {
                StatusBadge(status: item.status)
                Text(item.createdAt, style: .relative).foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }

    private var failureCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Couldn't process this", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)
            if let reason = item.failureReason {
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text("You can retry, or file it into a folder manually from the menu above.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button { retryProcessing() } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func retryProcessing() {
        item.status = .pending
        item.failureReason = nil
        dismiss()
        Task { await onRetry() }
    }

    private var settingsMenu: some View {
        Menu {
            if item.status == .failed {
                Button { retryProcessing() } label: { Label("Retry", systemImage: "arrow.clockwise") }
                Divider()
            }
            Button { editor = .category } label: { Label("Change Folder", systemImage: "folder") }
            Button { editor = .tags } label: { Label("Edit Tags", systemImage: "number") }
            Button { editor = .description } label: { Label("Edit Description", systemImage: "text.alignleft") }
            Divider()
            Button {
                item.toggleArchive()
                dismiss()
            } label: {
                Label(item.isArchived ? "Unarchive" : "Archive", systemImage: "archivebox")
            }
            Button(role: .destructive) { confirmingDelete = true } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
    }
}

/// Read-only badge showing the item's current folder.
struct CategoryBadge: View {
    let category: String?
    var body: some View {
        Label(category ?? "Unfiled", systemImage: categorySymbol(category ?? ""))
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.tint.opacity(0.15), in: Capsule())
            .foregroundStyle(.tint)
    }
}

/// Bottom sheet to move the item to another folder.
struct CategoryEditorSheet: View {
    @Bindable var item: SavedItem
    @Environment(\.dismiss) private var dismiss

    private var options: [String] {
        var result = [Categories.notes] + CategoryStore().customFolders
        for name in Categories.suggestions where !result.contains(name) { result.append(name) }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(options, id: \.self) { name in
                    Button {
                        item.assignFolder(name)
                        dismiss()
                    } label: {
                        HStack {
                            Label(name, systemImage: categorySymbol(name)).foregroundStyle(.primary)
                            Spacer()
                            if item.category == name { Image(systemName: "checkmark").foregroundStyle(.tint) }
                        }
                    }
                }
            }
            .navigationTitle("Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Bottom sheet to edit the item's description (the user note shown above the AI summary).
struct DescriptionEditorSheet: View {
    @Bindable var item: SavedItem
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(item: SavedItem) {
        self.item = item
        _text = State(initialValue: item.note ?? "")
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .padding()
                .navigationTitle("Description")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { item.setNote(text); dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Bottom sheet to edit the item's tags.
struct TagsEditorSheet: View {
    @Bindable var item: SavedItem
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                FlowLayout(spacing: 8) {
                    ForEach(item.tags, id: \.self) { tag in
                        EditableTagChip(tag: tag, isEditing: true) { item.removeTag(tag) }
                    }
                    AddTagField(text: $newTag) {
                        item.addTag(newTag)
                        newTag = ""
                    }
                }
                .padding()
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}

struct EditableTagChip: View {
    let tag: String
    let isEditing: Bool
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)").font(.caption)
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill").font(.caption2)
                }
                .accessibilityLabel("Remove tag \(tag)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary, in: Capsule())
    }
}

struct AddTagField: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        TextField("add tag", text: $text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .frame(width: 90)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary, in: Capsule())
            .onSubmit(onSubmit)
    }
}

struct ImagePreview: View {
    let filename: String

    var body: some View {
        if let uiImage = UIImage(contentsOfFile: ImageStore.appGroup().url(for: filename).path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
                .frame(height: 160)
                .overlay { Image(systemName: "photo").font(.largeTitle).foregroundStyle(.secondary) }
        }
    }
}

/// Wrapping layout for tag chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: min(maxWidth, widest), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ItemDetailView(item: PreviewData.samples[0])
    }
    .modelContainer(PreviewData.container)
}
#endif
