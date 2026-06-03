import Vision
import CoreGraphics

/// On-device text recognition (Vision), shared by image and PDF extraction.
func recognizeText(in image: CGImage) async throws -> String {
    var request = RecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    let observations = try await request.perform(on: image)
    return observations
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")
}

/// On-device image classification (Vision) — what objects/scenes the image likely contains.
/// Returns the top English labels by confidence (so the AI can describe a photo without text).
func classifyImage(_ image: CGImage, maxLabels: Int = 6) async -> [String] {
    let request = ClassifyImageRequest()
    guard let observations = try? await request.perform(on: image) else { return [] }
    return observations
        .filter { $0.confidence > 0.15 }
        .sorted { $0.confidence > $1.confidence }
        .prefix(maxLabels)
        .map(\.identifier)
}
