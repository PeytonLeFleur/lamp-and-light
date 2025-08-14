import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var planService = PlanService()
    @StateObject private var confetti = ConfettiHost()
    @StateObject private var net = NetworkMonitor.shared
    @State private var dailyPlan: DailyPlan?
    @State private var profile: Profile?
    @State private var showingScriptureExpanded = false
    @State private var isLoadingPlan = false
    @State private var showWhySheet = false
    @State private var whyReasons: [String] = []
    @State private var whyThemes: [String] = []
    @State private var presentPaywall = false
    @State private var didCelebrate = false
    
    var body: some View {
        AppScaffold(title: "Lamp & Light", showGreetingIcon: true) {
            if !net.isOnline {
                Text("You are offline. Using saved plan and placeholders.")
                    .font(AppFontV3.caption())
                    .foregroundStyle(.secondary)
                    .card()
            }

            TopGreeting(name: (profile?.displayName?.split(separator: " ").first.map(String.init)) ?? "Friend")

            if let plan = dailyPlan, let profile = profile {
                // Scripture Card
                VStack(alignment: .leading, spacing: S.m) {
                    HStack {
                        Text("Today’s passage").font(AppFontV3.h2())
                        Spacer()
                        Badge(text: "\(max(1, Int(profile.streakCount)))-day ⭐️", color: S.mint)
                    }
                    Text(plan.scriptureRef ?? "").font(AppFontV3.h2())
                    Text(plan.scriptureText ?? "")
                        .font(AppFontV3.body())
                        .lineSpacing(4)
                    Text("Text: KJV").font(AppFontV3.caption()).foregroundStyle(.secondary)
                }
                .card()

                // Tiles
                HStack(spacing: S.m) {
                    FeatureTile(title: "Application", subtitle: short(plan.application), symbol: "target", tint: .green)
                    FeatureTile(title: "Prayer", subtitle: short(plan.prayer), symbol: "hands.sparkles.fill", tint: .blue)
                    FeatureTile(title: "Challenge", subtitle: short(plan.challenge), symbol: "flag.circle.fill", tint: .orange)
                }

                // Big Start button
                PillButton(title: "Start", style: .large, systemImage: "checkmark.circle.fill") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        markChallengeComplete(plan, profile: profile)
                    }
                }

                // Week progress footer
                let goal = max(1, Int(profile.weeklyGoal))
                let done = Int(profile.weeklyCompleted)
                Text("This week \(done)/\(goal) ⭐️")
                    .font(AppFontV3.caption())
                    .foregroundStyle(.secondary)
            } else if isLoadingPlan {
                LoadingCard(text: "Generating today's plan…")
            } else {
                LoadingCard(text: "Loading today's plan…")
            }
        }
        .overlay(ConfettiHosting(host: confetti).allowsHitTesting(false))
        .task { await loadProfileAndPlan() }
        .sheet(isPresented: $showWhySheet) { WhyThisPassageSheet(reference: dailyPlan?.scriptureRef ?? "", themes: whyThemes, reasons: whyReasons) }
        .sheet(isPresented: $presentPaywall) { PaywallView() }
    }
    
    private func short(_ s: String?) -> String {
        let txt = s ?? ""
        if txt.count <= 24 { return txt }
        return String(txt.prefix(24)) + "…"
    }
    
    private func presentWhy(plan: DailyPlan, profile: Profile) {
        // Use plan.crossrefs as themes; fall back to ScriptureStore themes for the reference
        var themes = plan.crossrefs ?? []
        if themes.isEmpty, let ref = plan.scriptureRef {
            let store = ScriptureStore()
            if let p = store.passages.first(where: { $0.reference == ref }) {
                themes = p.themes
            }
        }
        whyThemes = themes
        let rs = ThemeReasoner.reasons(context: viewContext, profile: profile, since: 30, passageThemes: themes)
        whyReasons = rs
        showWhySheet = true
    }
    
    private func regenerateBits(keeping plan: DailyPlan) {
        Task {
            guard let prof = plan.profile else { return }
            let tagsReq: NSFetchRequest<Entry> = Entry.fetchRequest()
            tagsReq.predicate = NSPredicate(format: "profile == %@", prof)
            let entries = (try? viewContext.fetch(tagsReq)) ?? []
            let allTags = entries.flatMap { $0.tags ?? [] }
            let recentThemes = Array(Set(allTags)).prefix(5)
            do {
                let bits = try await OpenAIClient.devotionalBits(
                    passageRef: plan.scriptureRef ?? "",
                    passageText: plan.scriptureText ?? "",
                    recentThemes: Array(recentThemes)
                )
                plan.application = bits.application
                plan.prayer = bits.prayer
                plan.challenge = bits.challenge
                plan.crossrefs = bits.crossrefs
                try? viewContext.save()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                Log.error("Regenerate error \(error.localizedDescription)")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
    
    private func loadProfileAndPlan() async {
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let profiles = try viewContext.fetch(fetchRequest)
            if let firstProfile = profiles.first {
                profile = firstProfile
                
                // Reset weekly progress if it's a new week
                StreakService.resetWeeklyIfNewWeek(context: viewContext, profile: firstProfile)
                
                // Check if we already have a plan for today
                let today = Calendar.current.startOfDay(for: Date())
                let planFetchRequest: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
                planFetchRequest.predicate = NSPredicate(format: "profile == %@ AND day == %@", firstProfile, today as NSDate)
                planFetchRequest.fetchLimit = 1
                
                if let existingPlan = try? viewContext.fetch(planFetchRequest).first {
                    dailyPlan = existingPlan
                } else {
                    // Generate new plan with AI
                    isLoadingPlan = true
                    dailyPlan = await planService.generateTodayPlan(context: viewContext, profile: firstProfile)
                    isLoadingPlan = false
                    
                    // Save the context
                    try? viewContext.save()
                }
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func copyPrayer() {
        if let prayer = dailyPlan?.prayer {
            UIPasteboard.general.string = prayer
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func markChallengeComplete(_ plan: DailyPlan, profile: Profile) {
        plan.status = "done"
        
        // Update streak and weekly progress
        StreakService.markActive(context: viewContext, profile: profile)
        StreakService.incrementWeekly(context: viewContext, profile: profile)
        
        try? viewContext.save()
        
        // Celebrate with haptics and confetti
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if !ReduceMotion.isOn { confetti.fire() } else {
            withAnimation(.easeInOut(duration: 0.5)) { didCelebrate.toggle() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { didCelebrate.toggle() }
        }
    }
    
    private func markChallengeSkipped(_ plan: DailyPlan) {
        plan.status = "skipped"
        try? viewContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

#Preview {
    TodayView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 