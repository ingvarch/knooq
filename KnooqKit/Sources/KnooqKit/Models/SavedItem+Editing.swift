import Foundation

/// Manual-edit operations. Centralize tag normalization and `openedAt` stamping here so the
/// UI never duplicates the rules (DRY). `openedAt` marks the item as touched (not stale).
@MainActor
extension SavedItem {
    public func addTag(_ raw: String) {
        let tag = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        openedAt = .now
    }

    public func removeTag(_ tag: String) {
        guard tags.contains(tag) else { return }
        tags.removeAll { $0 == tag }
        openedAt = .now
    }

    public func setCategory(_ category: ItemCategory?) {
        self.category = category
        openedAt = .now
    }

    public func toggleArchive() {
        isArchived.toggle()
    }
}
