import Foundation

/// Result of FM analysis. Sendable value, decoupled from the persistence model.
public struct ItemAnalysis: Sendable, Equatable {
    public let category: String
    public let tags: [String]
    public let title: String
    public let summary: String

    public init(category: String, tags: [String], title: String, summary: String) {
        self.category = category
        self.tags = tags
        self.title = title
        self.summary = summary
    }
}

extension ItemAnalysis {
    /// Builds a validated analysis from raw model output: category snapped to the fixed set,
    /// tags lowercased and capped. Single place enforcing these rules (DRY), so it is unit-tested
    /// independently of the model.
    public static func validated(
        rawCategory: String,
        allowed: [String],
        rawTags: [String],
        title: String,
        summary: String,
        maxTags: Int = 3
    ) -> ItemAnalysis {
        ItemAnalysis(
            category: Categories.validated(rawCategory, allowed: allowed),
            tags: Array(rawTags.map { $0.lowercased() }.prefix(maxTags)),
            title: title,
            summary: summary
        )
    }
}

/// Turns extracted text into structured analysis. Prod: FMAnalyzer; test: StubAnalyzer.
public protocol Analyzer: Sendable {
    func analyze(_ text: String) async throws -> ItemAnalysis
}
