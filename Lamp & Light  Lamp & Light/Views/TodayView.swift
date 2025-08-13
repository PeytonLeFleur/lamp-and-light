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
                            }
                            Text(plan.scriptureRef ?? "")
                                .font(AppFont.title())
                                .foregroundColor(AppColor.ink)
                            
                            DisclosureGroup("Read passage") {
                                Text(plan.scriptureText ?? "")
                                    .font(AppFont.body())
                                    .foregroundColor(AppColor.slate)
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
                        }
                        .card()
                        
                        // Prayer Card
                        VStack(alignment: .leading, spacing: 10) {
                            Badge(text: "Prayer", color: AppColor.sunshine.opacity(0.5))
                            Text(plan.prayer ?? "")
                                .font(AppFont.body())
                                .foregroundColor(AppColor.ink)
                                .italic()
                            
                            PillButton(title: "Copy Prayer", style: .secondary, systemImage: "doc.on.doc") {
                                copyPrayer()
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