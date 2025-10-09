import Foundation

// MARK: - File Size Formatting
extension FileItem {
    func formattedSize() -> String {
        // Match web formatting: 1024 base, 0 decimals for >= 10 or bytes, else 1 decimal
        let raw = Int64(size) ?? 0
        if raw < 0 { return "0 B" }
        var value = Double(raw)
        let units = ["B", "KB", "MB", "GB", "TB"]
        var unitIndex = 0
        while value >= 1024.0 && unitIndex < units.count - 1 {
            value /= 1024.0
            unitIndex += 1
        }
        let digits = (value >= 10.0 || unitIndex == 0) ? 0 : 1
        let formatted = String(format: "% .\(digits)f", value).replacingOccurrences(of: " ", with: "")
        return "\(formatted) \(units[unitIndex])"
    }
}
