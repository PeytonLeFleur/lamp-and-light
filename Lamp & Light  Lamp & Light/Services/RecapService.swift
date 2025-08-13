import CoreData
import Foundation

enum RecapService {
    static func generateThisWeek(context: NSManagedObjectContext, profile: Profile, now: Date = Date()) throws -> WeeklyRecap {
        let cal = Calendar.current
        let weekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        // Fetch or create
        if let existing = try fetch(context: context, profile: profile, weekStart: weekStart) { return existing }

        // Pull last 7 days entries and plans
        let from = cal.date(byAdding: .day, value: -6, to: now)!
        let entries = try fetchEntries(context: context, profile: profile, from: from, to: now)
        let plans   = try fetchPlans(context: context, profile: profile, from: from, to: now)

        // Metrics
        let prayers = entries.filter { $0.kind == "prayer" }.count
        let completed = plans.filter { $0.status == "done" }.count
        let tags = entries.flatMap { ($0.tags ?? []) }
        let topTags = Array(Dictionary(grouping: tags, by: { $0 }).mapValues(\.count).sorted { $0.value > $1.value }.map(\.key).prefix(3))

        let md = """
        # Weekly Walk Recap
        **Week of \(DateFormatter.localizedString(from: weekStart, dateStyle: .medium, timeStyle: .none))**

        ## Highlights
        • Prayers logged: \(prayers)
        • Challenges completed: \(completed)

        ## Scriptures
        \(plans.map { "• \($0.scriptureRef ?? "")" }.joined(separator: "\n"))

        ## Top themes
        \(topTags.map { "• \($0)" }.joined(separator: "\n"))

        ## Gratitude
        Write one thing you are thankful for right now.
        """

        let recap = WeeklyRecap(context: context)
        recap.id = UUID()
        recap.weekStart = weekStart
        recap.recapMD = md
        recap.metrics = ["prayers": prayers, "completed": completed, "topTags": topTags] as [String: Any]
        recap.profile = profile
        try context.save()
        Log.info("Generated recap for week starting \(weekStart)")
        Analytics.track("recap_generated")
        Ratings.maybeAsk(for: "recap")
        return recap
    }

    private static func fetch(context: NSManagedObjectContext, profile: Profile, weekStart: Date) throws -> WeeklyRecap? {
        let req: NSFetchRequest<WeeklyRecap> = WeeklyRecap.fetchRequest()
        req.predicate = NSPredicate(format: "profile == %@ AND weekStart == %@", profile, weekStart as NSDate)
        req.fetchLimit = 1
        return try context.fetch(req).first
    }

    private static func fetchEntries(context: NSManagedObjectContext, profile: Profile, from: Date, to: Date) throws -> [Entry] {
        let r: NSFetchRequest<Entry> = Entry.fetchRequest()
        r.predicate = NSPredicate(format: "profile == %@ AND createdAt >= %@ AND createdAt <= %@", profile, from as NSDate, to as NSDate)
        return try context.fetch(r)
    }

    private static func fetchPlans(context: NSManagedObjectContext, profile: Profile, from: Date, to: Date) throws -> [DailyPlan] {
        let r: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
        r.predicate = NSPredicate(format: "profile == %@ AND day >= %@ AND day <= %@", profile, from as NSDate, to as NSDate)
        return try context.fetch(r)
    }
} 