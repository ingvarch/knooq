import Foundation

/// Tri-state tag selection.
/// - `allTags`: nil = off, true = all tagged items, false = untagged items.
/// - `states[tag]`: true = include (must have), false = exclude (must not have), absent = off.
/// `allTags` and per-tag states are mutually exclusive (choosing one clears the other).
public struct TagSelection: Hashable, Sendable {
    public var allTags: Bool?
    public var states: [String: Bool]

    public init(allTags: Bool? = nil, states: [String: Bool] = [:]) {
        self.allTags = allTags
        self.states = states
    }

    public static func includingTag(_ tag: String) -> TagSelection {
        TagSelection(states: [tag: true])
    }

    public static let allTagged = TagSelection(allTags: true)
}

@MainActor
public enum TagFiltering {

    public static func filter(_ items: [SavedItem], selection: TagSelection) -> [SavedItem] {
        if selection.allTags == true { return items.filter { !$0.tags.isEmpty } }
        if selection.allTags == false { return items.filter { $0.tags.isEmpty } }

        let includes = Set(selection.states.filter { $0.value }.map(\.key))
        let excludes = Set(selection.states.filter { !$0.value }.map(\.key))
        return items.filter { item in
            let tags = Set(item.tags)
            if !includes.isEmpty, tags.isDisjoint(with: includes) { return false }
            if !tags.isDisjoint(with: excludes) { return false }
            return true
        }
    }

    public static func title(_ selection: TagSelection) -> String {
        if selection.allTags == true { return "All Tags" }
        if selection.allTags == false { return "Untagged" }
        let count = selection.states.count
        if count == 0 { return "Tags" }
        if count == 1, let entry = selection.states.first {
            return entry.value ? "#\(entry.key)" : "Not #\(entry.key)"
        }
        return "\(count) Tags"
    }

    /// Cycle a tag: off -> include -> exclude -> off. Choosing a tag clears the All Tags mode.
    public static func cycle(_ selection: inout TagSelection, tag: String) {
        selection.allTags = nil
        switch selection.states[tag] {
        case nil: selection.states[tag] = true
        case .some(true): selection.states[tag] = false
        case .some(false): selection.states[tag] = nil
        }
    }

    /// Cycle All Tags: off -> all tagged -> untagged -> off. Clears per-tag states.
    public static func cycleAllTags(_ selection: inout TagSelection) {
        selection.states = [:]
        switch selection.allTags {
        case nil: selection.allTags = true
        case .some(true): selection.allTags = false
        case .some(false): selection.allTags = nil
        }
    }
}
