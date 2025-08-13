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

        // Check cache first
        if let cached = AICache.shared.get(ref: passage.reference, day: today) {
            newPlan.application = cached.application
            newPlan.prayer = cached.prayer
            newPlan.challenge = cached.challenge
            newPlan.crossrefs = cached.crossrefs
        } else {
            // Try to generate AI content, fall back to placeholders if it fails
            do {
                var bits = try await OpenAIClient.devotionalBits(
                    passageRef: passage.reference,
                    passageText: passage.text,
                    recentThemes: Array(allTags.prefix(5))
                )
                
                // Apply content length limits and fallbacks
                if bits.application.count > 800 {
                    bits = OpenAIClient.PlanBits(
                        application: String(bits.application.prefix(800)) + "…",
                        prayer: bits.prayer,
                        challenge: bits.challenge,
                        crossrefs: bits.crossrefs
                    )
                }
                if bits.prayer.count > 800 {
                    bits = OpenAIClient.PlanBits(
                        application: bits.application,
                        prayer: String(bits.prayer.prefix(800)) + "…",
                        challenge: bits.challenge,
                        crossrefs: bits.crossrefs
                    )
                }
                if bits.challenge.count > 200 {
                    bits = OpenAIClient.PlanBits(
                        application: bits.application,
                        prayer: bits.prayer,
                        challenge: String(bits.challenge.prefix(200)) + "…",
                        crossrefs: bits.crossrefs
                    )
                }
                
                // Cache the result
                AICache.shared.set(ref: passage.reference, day: today, bits: bits)
                
                newPlan.application = bits.application
                newPlan.prayer = bits.prayer
                newPlan.challenge = bits.challenge
                newPlan.crossrefs = bits.crossrefs
            } catch {
                // One retry after 500ms
                do {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let bits = try await OpenAIClient.devotionalBits(
                        passageRef: passage.reference,
                        passageText: passage.text,
                        recentThemes: Array(allTags.prefix(5))
                    )
                    
                    // Apply guards and cache
                    var retryBits = bits
                    if retryBits.application.count > 800 {
                        retryBits = OpenAIClient.PlanBits(
                            application: String(retryBits.application.prefix(800)) + "…",
                            prayer: retryBits.prayer,
                            challenge: retryBits.challenge,
                            crossrefs: retryBits.crossrefs
                        )
                    }
                    if retryBits.prayer.count > 800 {
                        retryBits = OpenAIClient.PlanBits(
                            application: retryBits.application,
                            prayer: String(retryBits.prayer.prefix(800)) + "…",
                            challenge: retryBits.challenge,
                            crossrefs: retryBits.crossrefs
                        )
                    }
                    if retryBits.challenge.count > 200 {
                        retryBits = OpenAIClient.PlanBits(
                            application: retryBits.application,
                            prayer: retryBits.prayer,
                            challenge: String(retryBits.challenge.prefix(200)) + "…",
                            crossrefs: retryBits.crossrefs
                        )
                    }
                    
                    AICache.shared.set(ref: passage.reference, day: today, bits: retryBits)
                    
                    newPlan.application = retryBits.application
                    newPlan.prayer = retryBits.prayer
                    newPlan.challenge = retryBits.challenge
                    newPlan.crossrefs = retryBits.crossrefs
                } catch {
                    // Fallback to placeholders
                    newPlan.application = "A short reflection on this passage for today."
                    newPlan.prayer = "Lord, help me trust you and walk in your word today. Amen."
                    newPlan.challenge = "Spend five quiet minutes praying through this passage."
                }
            }
        }

        return newPlan
    }
} 