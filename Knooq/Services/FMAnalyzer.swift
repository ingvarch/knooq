import Foundation
import FoundationModels
import KnooqKit

/// Structured output schema for Guided Generation.
@Generable
struct FMItemAnalysis {
    @Guide(description: "The single best-fitting folder name for this content, taken from the list in the instructions")
    var category: String

    @Guide(description: "Exactly 3 short lowercase tags describing the content. Each tag is a single token with no spaces; join multi-word tags with a hyphen (e.g. machine-learning)")
    var tags: [String]

    var title: String

    @Guide(description: "One concise sentence capturing the gist of the content (the TL;DR).")
    var tldr: String

    @Guide(description: "3 to 5 bullet points, each a key detail or useful takeaway from the content. Each is a full, self-contained sentence with no leading bullet character.")
    var keyPoints: [String]
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
        2. Generate exactly 3 relevant lowercase tags. Never put a space in a tag; join multi-word tags with a hyphen (e.g. "machine-learning").
        3. Create a concise, descriptive title.
        4. Write a one-sentence TL;DR capturing the gist.
        5. Write 3 to 5 key points, each a full sentence covering a key detail or useful takeaway.
        Summarize the actual article content, not the website or app it came from.
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
            summary: ItemSummary.format(tldr: fm.tldr, keyPoints: fm.keyPoints)
        )
    }
}
