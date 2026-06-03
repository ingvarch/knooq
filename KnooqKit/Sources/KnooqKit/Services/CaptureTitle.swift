import Foundation

/// Provisional "Share from …" title set at capture time so an item is never blank before FM
/// runs (and stays meaningful if FM is unavailable). FM refines it later for non-user-titled items.
public enum CaptureTitle {
    public static func provisional(rawType: RawType, urlString: String?, text: String?) -> String {
        switch rawType {
        case .url:
            if let host = urlString.flatMap(URL.init(string:))?.host() {
                return "Share from \(host.hasPrefix("www.") ? String(host.dropFirst(4)) : host)"
            }
            return "Shared link"
        case .text:
            return "Shared note"
        case .image:
            return "Shared image"
        case .pdf:
            return "Shared PDF"
        }
    }
}
