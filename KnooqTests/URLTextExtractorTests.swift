import Testing
import Foundation
@testable import Knooq

@MainActor
@Suite struct URLTextExtractorTests {

    private let articleHTML = """
    <!DOCTYPE html><html><head><title>Knooq</title></head><body>
    <nav>Home About Contact Login Signup</nav>
    <article>
      <h1>Capture, Organize, Resurface</h1>
      <p>Knooq turns saved links into memory. \(String(repeating: "It catches what you save, sorts it on device, and brings it back before you forget. ", count: 12))</p>
    </article>
    <footer>Copyright 2026 Knooq Footer Links Privacy Terms</footer>
    </body></html>
    """

    @Test func extractsArticleText() async throws {
        let extractor = URLTextExtractor()
        let text = try await extractor.extract(fromHTML: articleHTML, baseURL: URL(string: "https://knooq.app"))
        #expect(text.contains("Knooq turns saved links into memory"))
        #expect(text.count > 100)
    }

    @Test func throwsOnUnreachableURL() async {
        let extractor = URLTextExtractor(timeout: 5)
        await #expect(throws: (any Error).self) {
            _ = try await extractor.extract(from: URL(string: "https://knooq-does-not-exist.invalid/")!)
        }
    }
}
