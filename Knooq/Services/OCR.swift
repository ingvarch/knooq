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
