import Foundation

/// Deterministic source tag for an item, derived from its raw payload (never from FM).
/// `tags[0]` describes where content came from: a social platform, a site domain, or the
/// capture type (pdf/image/note). Pure logic, unit-tested independently of FM/network.
public enum SourceTag {

    /// Host (or any subdomain of it) -> canonical platform name. Single source of truth.
    private static let platforms: [(suffix: String, name: String)] = [
        ("instagram.com", "instagram"), ("instagr.am", "instagram"),
        ("facebook.com", "facebook"), ("fb.com", "facebook"),
        ("t.me", "telegram"), ("telegram.me", "telegram"), ("telegram.org", "telegram"),
        ("wa.me", "whatsapp"), ("whatsapp.com", "whatsapp"),
        ("youtube.com", "youtube"), ("youtu.be", "youtube"),
        ("x.com", "x"), ("twitter.com", "x"), ("t.co", "x"),
        ("tiktok.com", "tiktok"),
        ("reddit.com", "reddit"), ("redd.it", "reddit"),
        ("linkedin.com", "linkedin"), ("lnkd.in", "linkedin"),
    ]

    /// The source tag for an item, or nil if none applies (FM then fills all slots).
    public static func `for`(rawType: RawType, rawURL: URL?) -> String? {
        switch rawType {
        case .pdf: return "pdf"
        case .image: return "image"
        case .text: return "note"
        case .url:
            guard let host = normalizedHost(rawURL) else { return nil }
            return platform(for: host) ?? domainLabel(host)
        }
    }

    /// Merge source tag with FM tags: source at index 0, case-insensitive dedup, capped.
    public static func compose(source: String?, fmTags: [String], max: Int) -> [String] {
        var result: [String] = []
        var seen = Set<String>()
        for tag in ([source].compactMap { $0 } + fmTags) {
            let key = tag.lowercased()
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(tag)
            if result.count == max { break }
        }
        return result
    }

    // MARK: - Host parsing

    /// Lowercased host with a leading `www.` / `m.` stripped; nil if no host.
    private static func normalizedHost(_ url: URL?) -> String? {
        guard let host = url?.host()?.lowercased(), !host.isEmpty else { return nil }
        for prefix in ["www.", "m."] where host.hasPrefix(prefix) {
            return String(host.dropFirst(prefix.count))
        }
        return host
    }

    /// Platform name if the host equals or is a subdomain of a table entry.
    private static func platform(for host: String) -> String? {
        for entry in platforms where host == entry.suffix || host.hasSuffix("." + entry.suffix) {
            return entry.name
        }
        return nil
    }

    /// Generic registrable label: second-to-last dot component (e.g. nytimes.com -> nytimes).
    /// Known limitation: multi-part TLDs (bbc.co.uk -> co). See design doc; needs a PSL to fix.
    private static func domainLabel(_ host: String) -> String? {
        let parts = host.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        return String(parts[parts.count - 2])
    }
}
