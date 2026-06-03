import SwiftUI
import KnooqKit

/// Full-screen capture screen: Close / Save, a "SAVE TO" category picker (push), and the
/// shared content with a preview + editable text. No title field.
struct ShareCaptureView: View {
    let payload: SharePayload
    let onCancel: () -> Void
    let onSave: (String?, String) -> Void

    @State private var category: String?
    @State private var note: String

    init(payload: SharePayload, onCancel: @escaping () -> Void, onSave: @escaping (String?, String) -> Void) {
        self.payload = payload
        self.onCancel = onCancel
        self.onSave = onSave
        // For text shares the editable field starts as the shared text itself.
        _note = State(initialValue: payload.rawType == .text ? (payload.text ?? "") : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Save to") {
                    NavigationLink {
                        CategoryPickerView(selection: $category)
                    } label: {
                        HStack {
                            Text("Category")
                            Spacer()
                            Text(category ?? "Auto")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(payload.rawType == .text ? "Text" : "Content") {
                    ContentPreview(payload: payload)
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty {
                                Text(payload.rawType == .text ? "Edit text…" : "Add a note (optional)…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .navigationTitle("Save to Knooq")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onCancel() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(category, note) }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Preview of the shared item: rich link card, image, or nothing for plain text.
struct ContentPreview: View {
    let payload: SharePayload

    var body: some View {
        switch payload.rawType {
        case .url:
            if let url = payload.url {
                LinkPreview(url: url).frame(height: 110)
            }
        case .image:
            if let data = payload.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        case .pdf:
            Label("PDF", systemImage: "doc.richtext")
                .foregroundStyle(.secondary)
        case .text:
            EmptyView()
        }
    }
}

/// Category list pushed from the "Save to" row. Selecting pops back and updates the row.
struct CategoryPickerView: View {
    @Binding var selection: String?
    @Environment(\.dismiss) private var dismiss

    /// Auto (let AI decide) + Notes + user's custom folders + built-in suggestions.
    private var options: [String] {
        var result = [Categories.notes] + CategoryStore().customFolders
        for name in Categories.suggestions where !result.contains(name) { result.append(name) }
        return result
    }

    var body: some View {
        List {
            row("Auto", isOn: selection == nil) { selection = nil; dismiss() }
            ForEach(options, id: \.self) { category in
                row(category, isOn: selection == category) {
                    selection = category
                    dismiss()
                }
            }
        }
        .navigationTitle("Category")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer()
                if isOn { Image(systemName: "checkmark").foregroundStyle(.tint) }
            }
        }
    }
}
