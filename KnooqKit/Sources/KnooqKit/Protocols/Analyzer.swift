import Foundation

/// Result of FM analysis. Sendable value, decoupled from the persistence model.
public struct ItemAnalysis: Sendable, Equatable {
    public let category: ItemCategory
    public let tags: [String]
    public let title: String
    public let summary: String

    public init(category: ItemCategory, tags: [String], title: String, summary: String) {
        self.category = category
        self.tags = tags
        self.title = title
        self.summary = summary
    }
}

/// Turns extracted text into structured analysis. Prod: FMAnalyzer; test: StubAnalyzer.
public protocol Analyzer: Sendable {
    func analyze(_ text: String) async throws -> ItemAnalysis
}
