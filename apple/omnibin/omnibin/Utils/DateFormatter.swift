import Foundation

// MARK: - Date Formatting
extension BinItem {
    func formattedCreatedAt() -> String {
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .short
        outputFormatter.locale = Locale.current

        // Parse ISO8601 with and without fractional seconds
        let isoWithFractional: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        let isoNoFractional: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()

        let date = isoWithFractional.date(from: createdAt) ?? isoNoFractional.date(from: createdAt)
        if let date = date {
            return outputFormatter.string(from: date)
        }

        // Fallback: show raw timestamp if parsing fails (avoid showing "now")
        return createdAt
    }
}
