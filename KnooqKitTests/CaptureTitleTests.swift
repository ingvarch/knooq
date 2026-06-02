import Testing
@testable import KnooqKit

@Suite struct CaptureTitleTests {

    @Test func urlUsesShareFromHost() {
        #expect(CaptureTitle.provisional(rawType: .url, urlString: "https://www.instagram.com/p/x", text: nil) == "Share from instagram.com")
    }

    @Test func urlWithoutHostFallsBack() {
        #expect(CaptureTitle.provisional(rawType: .url, urlString: nil, text: nil) == "Shared link")
    }

    @Test func textIsSharedNote() {
        #expect(CaptureTitle.provisional(rawType: .text, urlString: nil, text: "anything") == "Shared note")
    }

    @Test func imageIsSharedImage() {
        #expect(CaptureTitle.provisional(rawType: .image, urlString: nil, text: nil) == "Shared image")
    }
}
