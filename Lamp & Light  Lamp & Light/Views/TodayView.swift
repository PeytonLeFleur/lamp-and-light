import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var planService = PlanService()
    @StateObject private var confetti = ConfettiHost()
    @State private var dailyPlan: DailyPlan?
    @State private var profile: Profile?
    @State private var showingScriptureExpanded = false
    @State private var isLoadingPlan = false
    @State private var showWhySheet = false
    @State private var whyReasons: [String] = []
    @State private var whyThemes: [String] = []
    
    var body: some View {
        NavigationView {
            AppBackground {
                VStack(spacing: 14) {
                    if let plan = dailyPlan, let profile = profile {
                        StreakHeader(name: profile.displayName ?? "Friend", days: Int(profile.streakCount))
                        
                        // Scripture Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Badge(text: "Scripture")
                                Spacer()
                                // Copy reference
                                Button {
                                    UIPasteboard.general.string = plan.scriptureRef
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                } label: { Image(systemName: "doc.on.doc").foregroundColor(AppColor.primaryGreen) }
                                // Why this passage
                                Button { presentWhy(plan: plan, profile: profile) } label: { Image(systemName: "info.circle").foregroundColor(AppColor.slate) }
                            }
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(plan.scriptureRef ?? "")
                                    .font(AppFont.title())
                                    .foregroundColor(AppColor.ink)
                            }
                            
                            DisclosureGroup("Read passage") {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(plan.scriptureText ?? "")
                                        .font(AppFont.body())
                                        .foregroundColor(AppColor.slate)
                                    Text("Text KJV Public Domain")
                                        .font(AppFont.caption())
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                                
                                if let crossrefs = plan.crossrefs, !crossrefs.isEmpty {
                                    Text("Cross-references: \(crossrefs.joined(separator: ", "))")
                                        .font(AppFont.caption())
                                        .foregroundColor(AppColor.slate.opacity(0.7))
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .card()
                        
                        // Application Card
                        VStack(alignment: .leading, spacing: 10) {
                            Badge(text: "Application", color: AppColor.sky.opacity(0.5))
                            Text(plan.application ?? "")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.ink)
                            
                            PillButton(title: "Refresh Application", style: .secondary, systemImage: "arrow.triangle.2.circlepath") {
                                regenerateBits(keeping: plan)
                            }
                        }
                        .card()
                        
                        // Prayer Card
                        VStack(alignment: .leading, spacing: 10) {
                            Badge(text: "Prayer", color: AppColor.sunshine.opacity(0.5))
                            Text(plan.prayer ?? "")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.ink)
                                .italic()
                            HStack {
                                PillButton(title: "Copy Prayer", style: .secondary, systemImage: "doc.on.doc") { copyPrayer() }
                            }
                        }
                        .card()
                        
                        // Challenge Card
                        VStack(alignment: .leading, spacing: 10) {
                            Badge(text: "Challenge", color: AppColor.softGreen)
                            Text(plan.challenge ?? "")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.ink)
                            
                            HStack(spacing: 12) {
                                PillButton(title: "Mark Done", style: .primary, systemImage: "checkmark.seal.fill") {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        markChallengeComplete(plan, profile: profile)
                                    }
                                }
                                PillButton(title: "Skip", style: .danger, systemImage: "xmark") {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        markChallengeSkipped(plan)
                                    }
                                }
                            }
                        }
                        .card()
                        
                        // Weekly Goal Card
                        VStack(alignment: .leading, spacing: 12) {
                            Badge(text: "Weekly Progress", color: AppColor.deepGreen)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    let goal = max(1, Int(profile.weeklyGoal))
                                    let done = Int(profile.weeklyCompleted)
                                    Text("\(done) of \(goal) challenges this week")
                                        .font(AppFont.body())
                                        .foregroundColor(AppColor.slate)
                                }
                                Spacer()
                                ProgressRing(progress: min(Double(profile.weeklyCompleted)/Double(max(1, profile.weeklyGoal)), 1.0))
                            }
                        }
                        .card()
                        
                        Spacer(minLength: 6)
                    } else if isLoadingPlan {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(AppColor.primaryGreen)
                            Text("Generating today's plan...")
                                .font(AppFont.headline())
                                .foregroundColor(AppColor.slate)
                            Text("AI is crafting personalized content for you")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.slate.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(AppColor.primaryGreen)
                            Text("Loading today's plan...")
                                .font(AppFont.headline())
                                .foregroundColor(AppColor.slate)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .overlay(ConfettiHosting(host: confetti).allowsHitTesting(false))
            .navigationTitle("Today")
            .task {
                await loadProfileAndPlan()
            }
            .sheet(isPresented: $showWhySheet) {
                WhyThisPassageSheet(reference: dailyPlan?.scriptureRef ?? "", themes: whyThemes, reasons: whyReasons)
            }
        }
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
        confetti.fire()
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