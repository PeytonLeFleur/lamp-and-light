import Foundation

struct OpenAIClient {
    static var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    }

    struct PlanBits: Codable {
        let application: String
        let prayer: String
        let challenge: String
        let crossrefs: [String]
    }

    static func devotionalBits(passageRef: String, passageText: String, recentThemes: [String]) async throws -> PlanBits {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")

        struct Body: Codable {
            struct Msg: Codable { let role: String; let content: String }
            let model: String
            let temperature: Double
            let messages: [Msg]
        }

        let system = """
        You are a careful Christian companion. Use only the given passage. Output JSON with fields: application, prayer, challenge, crossrefs.
        Application: 2-4 sentences with one contextual note. Prayer: four sentences, simple and reverent. Challenge: one small task under ten minutes. Avoid controversy and promises of material outcomes.
        """
        let user = """
        Passage: \(passageRef)
        Text: \(passageText)
        Recent themes: \(recentThemes.joined(separator: ", "))
        Respond with JSON only.
        """

        let body = Body(model: "gpt-4o-mini", temperature: 0.6, messages: [.init(role: "system", content: system), .init(role: "user", content: user)])
        req.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: req)
        struct Resp: Codable {
            struct Choice: Codable { struct Msg: Codable { let content: String }; let message: Msg }
            let choices: [Choice]
        }
        let resp = try JSONDecoder().decode(Resp.self, from: data)
        let content = resp.choices.first?.message.content ?? "{}"
        let jsonData = content.data(using: .utf8) ?? Data()
        let bits = try JSONDecoder().decode(PlanBits.self, from: jsonData)
        return bits
    }
} 