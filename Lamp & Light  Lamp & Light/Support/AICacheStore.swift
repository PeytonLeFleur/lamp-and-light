import Foundation

final class AICacheStore {
    static let shared = AICacheStore()
    private init() {}

    private func cacheDir() -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("AICache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func key(ref: String, day: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let d = df.string(from: Calendar.current.startOfDay(for: day))
        let safeRef = ref.replacingOccurrences(of: "[^A-Za-z0-9]+", with: "_", options: .regularExpression)
        return "\(safeRef)_\(d).json"
    }

    func load(ref: String, day: Date) -> PlanBits? {
        let url = cacheDir().appendingPathComponent(key(ref: ref, day: day))
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PlanBits.self, from: data)
    }

    func save(ref: String, day: Date, bits: PlanBits) {
        let url = cacheDir().appendingPathComponent(key(ref: ref, day: day))
        if let data = try? JSONEncoder().encode(bits) {
            try? data.write(to: url, options: .atomic)
        }
    }
} 