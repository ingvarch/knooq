import Foundation
import FoundationModels
import KnooqKit

/// Structured output schema for Guided Generation.
@Generable
struct FMItemAnalysis {
    @Guide(description: "The single best-fitting folder name for this content, taken from the list in the instructions")
    var category: String

    @Guide(description: "Exactly 3 short lowercase tags describing the content")
    var tags: [String]

    var title: String

    @Guide(description: "Formatted as: a line starting with 'TL;DR: ' and one concise sentence, then a blank line, then 3 to 5 bullet points, each on its own line starting with '• ', covering the key details and takeaways.")
    var summary: String
}

/// Production Analyzer backed by the on-device Foundation Model.
/// Checks availability first and degrades gracefully if the model is not usable.
final class FMAnalyzer: Analyzer {
    enum FMError: LocalizedError {
        case modelUnavailable(SystemLanguageModel.Availability)
        case unsafeContent

        var errorDescription: String? {
            if case .unsafeContent = self {
                return "Unsafe content detected by Apple Intelligence"
            }
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

    private func instructions(allowed: [String]) -> String {
        """
        You are a content categorization assistant. Analyze the provided text and:
        1. Choose the single best-fitting folder for this content from this list: \(allowed.joined(separator: ", ")).
           Prefer a folder the user already has. If nothing fits well, use \(Categories.other).
        2. Generate exactly 3 relevant lowercase tags.
        3. Create a concise, descriptive title.
        4. Write the summary in this exact shape:
           - First line: "TL;DR: " followed by one short sentence capturing the gist.
           - Then a blank line.
           - Then 3 to 5 bullet points, each on its own line starting with "• ", each a key detail or takeaway.
        Always use this TL;DR + bullets format. Focus on the most useful details of the content.
        """
    }

    func analyze(_ text: String) async throws -> ItemAnalysis {
        let availability = SystemLanguageModel.default.availability
        knooqLog("FMAnalyzer: availability = \(availability), input \(text.count) chars")
        guard case .available = availability else {
            throw FMError.modelUnavailable(availability)
        }

        let allowed = CategoryStore().allowedForAI()
        let session = LanguageModelSession(instructions: instructions(allowed: allowed))

        let response: LanguageModelSession.Response<FMItemAnalysis>
        do {
            response = try await session.respond(to: text, generating: FMItemAnalysis.self)
        } catch let error as LanguageModelSession.GenerationError {
            if case .guardrailViolation = error { throw FMError.unsafeContent }
            throw error
        }
        let fm = response.content
        knooqLog("FMAnalyzer: got category=\(fm.category) tags=\(fm.tags)")

        return ItemAnalysis.validated(
            rawCategory: fm.category,
            allowed: allowed,
            rawTags: fm.tags,
            title: fm.title,
            summary: fm.summary
        )
    }
}
