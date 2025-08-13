import Foundation
import CoreData

final class AICache {
    static let shared = AICache()
    private init() {}

    private var mem: [String: OpenAIClient.PlanBits] = [:]

    func key(ref: String, day: Date) -> String {
        let d = ISO8601DateFormatter()
        let dateOnly = Calendar.current.startOfDay(for: day)
        return "\(ref)|\(d.string(from: dateOnly))"
    }

    func get(ref: String, day: Date) -> OpenAIClient.PlanBits? {
        mem[key(ref: ref, day: day)]
    }

    func set(ref: String, day: Date, bits: OpenAIClient.PlanBits) {
        mem[key(ref: ref, day: day)] = bits
    }
} 