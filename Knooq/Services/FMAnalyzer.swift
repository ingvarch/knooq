import FoundationModels
import KnooqKit

/// Structured output schema for Guided Generation.
@Generable
struct FMItemAnalysis {
    @Guide(description: "One of: Article, Video, Recipe, Purchase, Travel, Idea, Tool, Other")
    var category: String

    @Guide(description: "3-6 short lowercase tags describing the content")
    var tags: [String]

    var title: String

    @Guide(description: "1-2 sentence summary of the content")
    var summary: String
}

/// Production Analyzer backed by the on-device Foundation Model.
/// Checks availability first and degrades gracefully if the model is not usable.
final class FMAnalyzer: Analyzer {
    enum FMError: Error {
        case modelUnavailable(SystemLanguageModel.Availability)
    }

    private let instructions = """
    You are a content categorization assistant. Analyze the provided text and:
    1. Categorize into exactly one of: Article, Video, Recipe, Purchase, Travel, Idea, Tool, Other.
    2. Generate 3-6 relevant lowercase tags.
    3. Create a concise title.
    4. Write a 1-2 sentence summary.
    Focus on the main topic and intent of the content.
    """

    func analyze(_ text: String) async throws -> ItemAnalysis {
        let availability = SystemLanguageModel.default.availability
        guard case .available = availability else {
            throw FMError.modelUnavailable(availability)
        }

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: text, generating: FMItemAnalysis.self)
        let fm = response.content

        return ItemAnalysis.validated(
            rawCategory: fm.category,
            rawTags: fm.tags,
            title: fm.title,
            summary: fm.summary
        )
    }
}
