import Testing
import Foundation
@testable import KnooqKit

@Suite struct SourceTagTests {

    private func url(_ s: String) -> URL { URL(string: s)! }

    // MARK: - Platform table

    @Test func instagramHost() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://instagram.com/p/abc")) == "instagram")
    }

    @Test func facebookShortHost() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://fb.com/xyz")) == "facebook")
    }

    @Test func telegramHost() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://t.me/channel/123")) == "telegram")
    }

    @Test func whatsappShortHost() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://wa.me/15551234")) == "whatsapp")
    }

    @Test func youtubeShortLink() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://youtu.be/dQw4")) == "youtube")
    }

    @Test func xAndTwitterBothMapToX() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://x.com/u/status/1")) == "x")
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://twitter.com/u/status/1")) == "x")
    }

    @Test func tiktokSubdomain() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://vm.tiktok.com/abc")) == "tiktok")
    }

    @Test func redditShortLink() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://redd.it/abc")) == "reddit")
    }

    @Test func linkedinHost() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://www.linkedin.com/feed")) == "linkedin")
    }

    // MARK: - Host normalization

    @Test func subdomainMatchesPlatform() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://m.facebook.com/story")) == "facebook")
    }

    @Test func wwwStrippedForGenericDomain() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://www.nytimes.com/2026/article")) == "nytimes")
    }

    @Test func caseInsensitiveHost() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://INSTAGRAM.COM/p/abc")) == "instagram")
    }

    // MARK: - Generic domain

    @Test func genericDomainSecondLevelLabel() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://theverge.com/tech")) == "theverge")
    }

    @Test func genericSubdomainTakesRegistrableLabel() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("https://blog.theverge.com/x")) == "theverge")
    }

    // MARK: - Non-URL raw types

    @Test func pdfType() {
        #expect(SourceTag.for(rawType: .pdf, rawURL: nil) == "pdf")
    }

    @Test func imageType() {
        #expect(SourceTag.for(rawType: .image, rawURL: nil) == "image")
    }

    @Test func textType() {
        #expect(SourceTag.for(rawType: .text, rawURL: nil) == "note")
    }

    // MARK: - URL edge cases

    @Test func urlTypeWithNilURLIsNil() {
        #expect(SourceTag.for(rawType: .url, rawURL: nil) == nil)
    }

    @Test func urlWithNoHostIsNil() {
        #expect(SourceTag.for(rawType: .url, rawURL: url("mailto:a@b.com")) == nil)
    }

    // MARK: - compose

    @Test func sourcePlusTwoFMCappedAtThree() {
        let tags = SourceTag.compose(source: "instagram", fmTags: ["recipe", "vegan", "dinner"], max: 3)
        #expect(tags == ["instagram", "recipe", "vegan"])
    }

    @Test func dedupFMRepeatingSourceCaseInsensitive() {
        let tags = SourceTag.compose(source: "instagram", fmTags: ["Instagram", "recipe", "vegan"], max: 3)
        #expect(tags == ["instagram", "recipe", "vegan"])
    }

    @Test func nilSourceKeepsFMTagsCapped() {
        let tags = SourceTag.compose(source: nil, fmTags: ["a", "b", "c", "d"], max: 3)
        #expect(tags == ["a", "b", "c"])
    }

    @Test func emptyFMWithSource() {
        let tags = SourceTag.compose(source: "pdf", fmTags: [], max: 3)
        #expect(tags == ["pdf"])
    }
}
