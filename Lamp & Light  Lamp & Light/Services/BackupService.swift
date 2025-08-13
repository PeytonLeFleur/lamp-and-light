import CoreData
import Foundation
import UniformTypeIdentifiers

enum BackupService {
    static func exportAll(context: NSManagedObjectContext, profile: Profile) throws -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("LampAndLight-\(UUID().uuidString).json")
        var payload: [String: Any] = [:]

        func fetch<T: NSManagedObject>(_ req: NSFetchRequest<T>) -> [T] { (try? context.fetch(req)) ?? [] }

        payload["profile"] = [
            "name": profile.displayName ?? "",
            "goals": profile.goals ?? "",
            "streak": profile.streakCount,
            "weeklyGoal": profile.weeklyGoal,
            "weeklyCompleted": profile.weeklyCompleted
        ]

        let eReq: NSFetchRequest<Entry> = Entry.fetchRequest()
        eReq.predicate = NSPredicate(format: "profile == %@", profile)
        let entries = fetch(eReq).map { e in
            [
                "id": e.id?.uuidString ?? "",
                "createdAt": e.createdAt?.timeIntervalSince1970 ?? 0,
                "kind": e.kind ?? "",
                "content": e.content ?? "",
                "tags": e.tags ?? [],
                "emotion": e.emotion ?? ""
            ] as [String : Any]
        }

        let dReq: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
        dReq.predicate = NSPredicate(format: "profile == %@", profile)
        let plans = fetch(dReq).map { p in
            [
                "day": p.day?.timeIntervalSince1970 ?? 0,
                "ref": p.scriptureRef ?? "",
                "text": p.scriptureText ?? "",
                "application": p.application ?? "",
                "prayer": p.prayer ?? "",
                "challenge": p.challenge ?? "",
                "status": p.status ?? ""
            ] as [String: Any]
        }

        payload["entries"] = entries
        payload["plans"] = plans

        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        try data.write(to: tmp)
        return tmp
    }
} 