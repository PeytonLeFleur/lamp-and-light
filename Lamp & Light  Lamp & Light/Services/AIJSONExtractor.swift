import Foundation

enum AIJSONExtractor {
    static func extractJSONObject(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "{") else { return nil }
        var depth = 0
        var idx = start
        while idx < text.endIndex {
            let ch = text[idx]
            if ch == "{" { depth += 1 }
            if ch == "}" {
                depth -= 1
                if depth == 0 {
                    let slice = text[start...idx]
                    return slice.data(using: .utf8)
                }
            }
            idx = text.index(after: idx)
        }
        return nil
    }
} 