import Foundation

/// Computes which folders to show in the inbox: Notes (always) + the user's custom folders +
/// any other category that currently has items (built-ins the AI used, or Other). "All" is a
/// separate UI affordance, not part of this list.
public enum Folders {
    public static func visible(custom: [String], used: Set<String>) -> [String] {
        var result = [Categories.notes]
        result += custom.filter { $0.caseInsensitiveCompare(Categories.notes) != .orderedSame }
        let extras = used.subtracting(result).sorted()
        result += extras
        return result
    }
}
