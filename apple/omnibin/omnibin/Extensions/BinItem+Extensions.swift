import Foundation

// MARK: - BinItem Computed Properties
extension BinItem {
    var isText: Bool {
        kind == "TEXT"
    }
    
    var isFile: Bool {
        kind == "FILE"
    }
}
