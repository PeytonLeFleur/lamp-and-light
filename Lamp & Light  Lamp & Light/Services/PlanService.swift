import Foundation
import CoreData

class PlanService: ObservableObject {
    private let scriptureStore = ScriptureStore()

    static func generateOrFetchToday(context: NSManagedObjectContext, profile: Profile) async -> DailyPlan {
        if let existing = PlanRefresher.existingPlan(context: context, profile: profile) {
            return existing
        }
        return await PlanService().generateTodayPlan(context: context, profile: profile)
    }

    func generateTodayPlan(context: NSManagedObjectContext, profile: Profile) async -> DailyPlan {
        let today = Calendar.current.startOfDay(for: Date())
        let fetchRequest: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profile == %@ AND day == %@", profile, today as NSDate)
        fetchRequest.fetchLimit = 1

        if let existingPlan = try? context.fetch(fetchRequest).first {
            Log.info("Using existing plan for today")
            return existingPlan
        }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let entryFetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        entryFetchRequest.predicate = NSPredicate(format: "profile == %@ AND createdAt >= %@", profile, thirtyDaysAgo as NSDate)
        let recentEntries = (try? context.fetch(entryFetchRequest)) ?? []

        var allTags: [String] = []
        for entry in recentEntries {
            let tags = entry.tags ?? []
            allTags.append(contentsOf: tags)
        }
        let dedupedThemes = Array(Set(allTags)).prefix(5)

        let passage = allTags.isEmpty ? scriptureStore.pickRandom() : scriptureStore.pick(byThemes: allTags)
        Log.info("Picked passage \(passage.reference)")

        let newPlan = DailyPlan(context: context)
        newPlan.id = UUID()
        newPlan.day = today
        newPlan.scriptureRef = passage.reference
        newPlan.scriptureText = passage.text
        newPlan.crossrefs = passage.crossrefs
        newPlan.status = "active"
        newPlan.profile = profile

        // Disk cache first
        if let cached = AICacheStore.shared.load(ref: passage.reference, day: today) {
            Log.info("Using disk cached AI bits for \(passage.reference)")
            newPlan.application = cached.application
            newPlan.prayer = cached.prayer
            newPlan.challenge = cached.challenge
            newPlan.crossrefs = cached.crossrefs
        } else {
            // Offline guard: use placeholders if offline
            if NetworkMonitor.shared.isOnline == false {
                newPlan.application = "A short reflection on this passage for today."
                newPlan.prayer = "Lord, help me trust you and walk in your word today. Amen."
                newPlan.challenge = "Spend five quiet minutes praying through this passage."
                return newPlan
            }
            do {
                Log.info("Requesting AI bits for \(passage.reference)")
                var bits = try await OpenAIClient.devotionalBits(
                    passageRef: passage.reference,
                    passageText: passage.text,
                    recentThemes: Array(dedupedThemes)
                )
                if bits.application.count > 800 { bits = PlanBits(application: String(bits.application.prefix(800)) + "…", prayer: bits.prayer, challenge: bits.challenge, crossrefs: bits.crossrefs) }
                if bits.prayer.count > 800 { bits = PlanBits(application: bits.application, prayer: String(bits.prayer.prefix(800)) + "…", challenge: bits.challenge, crossrefs: bits.crossrefs) }
                if bits.challenge.count > 200 { bits = PlanBits(application: bits.application, prayer: bits.prayer, challenge: String(bits.challenge.prefix(200)) + "…", crossrefs: bits.crossrefs) }
                AICacheStore.shared.save(ref: passage.reference, day: today, bits: bits)
                newPlan.application = bits.application
                newPlan.prayer = bits.prayer
                newPlan.challenge = bits.challenge
                newPlan.crossrefs = bits.crossrefs
            } catch {
                Log.error("AI error \(error.localizedDescription)")
                do {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let bits2 = try await OpenAIClient.devotionalBits(
                        passageRef: passage.reference,
                        passageText: passage.text,
                        recentThemes: Array(dedupedThemes)
                    )
                    AICacheStore.shared.save(ref: passage.reference, day: today, bits: bits2)
                    newPlan.application = bits2.application
                    newPlan.prayer = bits2.prayer
                    newPlan.challenge = bits2.challenge
                    newPlan.crossrefs = bits2.crossrefs
                } catch {
                    Log.error("AI retry failed \(error.localizedDescription)")
                    newPlan.application = "A short reflection on this passage for today."
                    newPlan.prayer = "Lord, help me trust you and walk in your word today. Amen."
                    newPlan.challenge = "Spend five quiet minutes praying through this passage."
                }
            }
        }

        return newPlan
    }
} 