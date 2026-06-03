import Foundation

/// Persists the user's custom folders (BCP-free plain names). `Notes` is always present and is
/// not stored here. Backed by UserDefaults (injectable for tests).
public struct CategoryStore {
    private let defaults: UserDefaults
    private static let key = "knooq.categories.custom"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var customFolders: [String] {
        get { defaults.stringArray(forKey: Self.key) ?? [] }
        set { defaults.set(newValue, forKey: Self.key) }
    }

    public mutating func add(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var folders = customFolders
        guard !folders.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }),
              trimmed.caseInsensitiveCompare(Categories.notes) != .orderedSame else { return }
        folders.append(trimmed)
        customFolders = folders
    }

    public mutating func remove(_ name: String) {
        customFolders = customFolders.filter { $0 != name }
    }

    /// Categories the AI may choose from: Notes, the user's folders, and the built-in suggestions.
    public func allowedForAI() -> [String] {
        var result = [Categories.notes]
        result += customFolders
        for suggestion in Categories.suggestions where !result.contains(suggestion) {
            result.append(suggestion)
        }
        return result
    }
}
