import Testing
@testable import KnooqKit

@Suite struct ItemSummaryTests {

    @Test func tldrThenBullets() {
        let s = ItemSummary.format(tldr: "Drone hit Kuwait base.", keyPoints: ["Three injured", "Iran denies"])
        #expect(s == "TL;DR: Drone hit Kuwait base.\n\n• Three injured\n• Iran denies")
    }

    @Test func trimsWhitespace() {
        let s = ItemSummary.format(tldr: "  Gist.  ", keyPoints: ["  point  "])
        #expect(s == "TL;DR: Gist.\n\n• point")
    }

    @Test func dropsBlankPoints() {
        let s = ItemSummary.format(tldr: "Gist.", keyPoints: ["a", "  ", "", "b"])
        #expect(s == "TL;DR: Gist.\n\n• a\n• b")
    }

    @Test func tldrOnlyWhenNoPoints() {
        let s = ItemSummary.format(tldr: "Gist.", keyPoints: [])
        #expect(s == "TL;DR: Gist.")
    }

    @Test func bulletsOnlyWhenTldrBlank() {
        let s = ItemSummary.format(tldr: "   ", keyPoints: ["a", "b"])
        #expect(s == "• a\n• b")
    }
}
