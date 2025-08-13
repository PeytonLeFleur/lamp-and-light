import Foundation

enum AIJSONExtractor {
    static func extractJSONObject(from text: String) -> Data? {
        let trimmed = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
        guard let start = trimmed.firstIndex(of: "{") else { return nil }
        var depth = 0
        var idx = start
        while idx < trimmed.endIndex {
            let ch = trimmed[idx]
            if ch == "{" { depth += 1 }
            if ch == "}" {
                depth -= 1
                if depth == 0 {
                    let slice = trimmed[start...idx]
                    return slice.data(using: .utf8)
                }
            }
            idx = trimmed.index(after: idx)
        }
        return nil
    }
} 