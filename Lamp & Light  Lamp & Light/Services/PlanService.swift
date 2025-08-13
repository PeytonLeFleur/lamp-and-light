import Foundation
import CoreData

class PlanService: ObservableObject {
    private let scriptureStore = ScriptureStore()

    func generateTodayPlan(context: NSManagedObjectContext, profile: Profile) async -> DailyPlan {
        let today = Calendar.current.startOfDay(for: Date())
        let fetchRequest: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profile == %@ AND day == %@", profile, today as NSDate)
        fetchRequest.fetchLimit = 1

        if let existingPlan = try? context.fetch(fetchRequest).first {
            return existingPlan
        }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let entryFetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        entryFetchRequest.predicate = NSPredicate(format: "profile == %@ AND createdAt >= %@", profile, thirtyDaysAgo as NSDate)
        let recentEntries = (try? context.fetch(entryFetchRequest)) ?? []

        var allTags: [String] = []
        for entry in recentEntries {
            if let tags = entry.tags {
                allTags.append(contentsOf: tags)
            }
        }

        let passage = allTags.isEmpty ? scriptureStore.pickRandom() : scriptureStore.pick(byThemes: allTags)

        let newPlan = DailyPlan(context: context)
        newPlan.id = UUID()
        newPlan.day = today
        newPlan.scriptureRef = passage.reference
        newPlan.scriptureText = passage.text
        newPlan.crossrefs = passage.crossrefs
        newPlan.status = "active"
        newPlan.profile = profile

        // Try to generate AI content, fall back to placeholders if it fails
        do {
            let bits = try await OpenAIClient.devotionalBits(
                passageRef: passage.reference,
                passageText: passage.text,
                recentThemes: Array(allTags.prefix(5))
            )
            
            // Apply content length limits and fallbacks
            newPlan.application = bits.application.count > 800 ? String(bits.application.prefix(800)) + "…" : bits.application
            newPlan.prayer = bits.prayer.count > 800 ? String(bits.prayer.prefix(800)) + "…" : bits.prayer
            
            // Validate challenge length and ensure it's under 10 minutes
            var challenge = bits.challenge
            if challenge.count > 200 {
                challenge = String(challenge.prefix(200)) + "…"
            }
            
            // Simple validation for challenge duration
            let timeKeywords = ["hour", "hours", "30 minutes", "45 minutes", "20 minutes", "15 minutes"]
            if timeKeywords.contains(where: { challenge.lowercased().contains($0) }) {
                challenge = "Pray through this passage for five minutes and text one encouragement to a friend."
            }
            
            newPlan.challenge = challenge
            newPlan.crossrefs = bits.crossrefs
        } catch {
            // Fallback to placeholders
            newPlan.application = "A short reflection on this passage for today."
            newPlan.prayer = "Lord, help me trust you and walk in your word today. Amen."
            newPlan.challenge = "Spend five quiet minutes praying through this passage."
        }

        return newPlan
    }
} 