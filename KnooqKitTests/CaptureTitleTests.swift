import Testing
@testable import KnooqKit

@Suite struct CaptureTitleTests {

    @Test func urlUsesHost() {
        #expect(CaptureTitle.provisional(rawType: .url, urlString: "https://www.swift.org/blog", text: nil) == "swift.org")
    }

    @Test func urlWithoutHostFallsBack() {
        #expect(CaptureTitle.provisional(rawType: .url, urlString: nil, text: nil) == "Link")
    }

    @Test func textUsesTrimmedPrefix() {
        let title = CaptureTitle.provisional(rawType: .text, urlString: nil, text: "  Buy oat milk  ")
        #expect(title == "Buy oat milk")
    }

    @Test func emptyTextFallsBack() {
        #expect(CaptureTitle.provisional(rawType: .text, urlString: nil, text: "   ") == "Note")
    }

    @Test func longTextIsTruncated() {
        let long = String(repeating: "a", count: 100)
        #expect(CaptureTitle.provisional(rawType: .text, urlString: nil, text: long).count == 60)
    }

    @Test func imageHasLabel() {
        #expect(CaptureTitle.provisional(rawType: .image, urlString: nil, text: nil) == "Image")
    }
}
