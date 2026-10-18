import Foundation
import UniformTypeIdentifiers

// MARK: - URL Helpers
func firstURL(in text: String) -> String? {
    let types: NSTextCheckingResult.CheckingType = .link
    let detector = try? NSDataDetector(types: types.rawValue)
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    let match = detector?.firstMatch(in: text, options: [], range: range)
    if let r = match?.range, let swiftRange = Range(r, in: text) {
        return String(text[swiftRange])
    }
    return nil
}

