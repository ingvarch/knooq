import Foundation
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
    enum FMError: LocalizedError {
        case modelUnavailable(SystemLanguageModel.Availability)

        var errorDescription: String? {
            guard case .modelUnavailable(let availability) = self else { return nil }
            switch availability {
            case .available:
                return "model available"
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Apple Intelligence is not enabled in Settings"
            case .unavailable(.deviceNotEligible):
                return "this device is not eligible for Apple Intelligence"
            case .unavailable(.modelNotReady):
                return "the model is still downloading or not ready"
            case .unavailable(let other):
                return "model unavailable (\(other))"
            }
        }
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
        knooqLog("FMAnalyzer: availability = \(availability), input \(text.count) chars")
        guard case .available = availability else {
            throw FMError.modelUnavailable(availability)
        }

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: text, generating: FMItemAnalysis.self)
        let fm = response.content
        knooqLog("FMAnalyzer: got category=\(fm.category) tags=\(fm.tags)")

        return ItemAnalysis.validated(
            rawCategory: fm.category,
            rawTags: fm.tags,
            title: fm.title,
            summary: fm.summary
        )
    }
}
