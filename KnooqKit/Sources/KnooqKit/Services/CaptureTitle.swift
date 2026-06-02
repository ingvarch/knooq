import Foundation

/// Provisional, human-readable title set at capture time so an item is never blank
/// before FM runs (and stays meaningful if FM is unavailable). FM refines it later.
public enum CaptureTitle {
    public static func provisional(rawType: RawType, urlString: String?, text: String?) -> String {
        switch rawType {
        case .url:
            if let host = urlString.flatMap(URL.init(string:))?.host() {
                return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            }
            return "Link"
        case .text:
            let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Note" : String(trimmed.prefix(60))
        case .image:
            return "Image"
        }
    }
}
