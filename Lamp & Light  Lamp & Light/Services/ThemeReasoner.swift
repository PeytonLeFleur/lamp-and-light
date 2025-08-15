import CoreData
import Foundation

enum ThemeReasoner {
    static func reasons(context: NSManagedObjectContext, profile: Profile, since days: Int = 30, passageThemes: [String]) -> [String] {
        let from = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let r: NSFetchRequest<Entry> = Entry.fetchRequest()
        r.predicate = NSPredicate(format: "profile == %@ AND createdAt >= %@", profile, from as NSDate)
        let entries = (try? context.fetch(r)) ?? []
        let tags = entries.flatMap { $0.tags ?? [] }.map { $0.lowercased() }
        var hits: [String:Int] = [:]
        for t in tags {
            if passageThemes.contains(where: { t.contains($0.lowercased()) || $0.lowercased().contains(t) }) {
                hits[t, default: 0] += 1
            }
        }
        if hits.isEmpty { return Array(passageThemes.prefix(2)) }
        return Array(hits.sorted { $0.value > $1.value }.map(\.key).prefix(3))
    }
} 