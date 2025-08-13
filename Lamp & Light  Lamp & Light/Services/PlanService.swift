import Foundation
import CoreData

class PlanService: ObservableObject {
    private let scriptureStore = ScriptureStore()
    
    func generateTodayPlan(context: NSManagedObjectContext, profile: Profile) -> DailyPlan {
        // Check if a plan for today already exists
        let today = Calendar.current.startOfDay(for: Date())
        
        let fetchRequest: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profile == %@ AND day == %@", profile, today as NSDate)
        fetchRequest.fetchLimit = 1
        
        if let existingPlan = try? context.fetch(fetchRequest).first {
            return existingPlan
        }
        
        // Collect tags from last 30 days of entries
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let entryFetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        entryFetchRequest.predicate = NSPredicate(format: "profile == %@ AND createdAt >= %@", profile, thirtyDaysAgo as NSDate)
        
        let recentEntries = (try? context.fetch(entryFetchRequest)) ?? []
        
        // Extract all tags from recent entries
        var allTags: [String] = []
        for entry in recentEntries {
            if let tags = entry.tags {
                allTags.append(contentsOf: tags)
            }
        }
        
        // Pick a passage based on themes from tags, or random if no tags
        let passage = allTags.isEmpty ? scriptureStore.pickRandom() : scriptureStore.pick(byThemes: allTags)
        
        // Create new daily plan
        let newPlan = DailyPlan(context: context)
        newPlan.id = UUID()
        newPlan.day = today
        newPlan.scriptureRef = passage.reference
        newPlan.scriptureText = passage.text
        newPlan.crossrefs = passage.crossrefs
        newPlan.application = "A short reflection on this passage for today."
        newPlan.prayer = "Lord, help me trust you and walk in your word today. Amen."
        newPlan.challenge = "Spend five quiet minutes praying through this passage."
        newPlan.status = "active"
        newPlan.profile = profile
        
        return newPlan
    }
} 