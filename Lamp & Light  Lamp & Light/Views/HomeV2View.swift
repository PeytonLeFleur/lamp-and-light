import SwiftUI
import CoreData

struct HomeV2View: View {
    @Environment(\.managedObjectContext) private var ctx

    // Hook to your current plan data
    @FetchRequest(entity: DailyPlan.entity(), sortDescriptors: [], predicate: NSPredicate(format: "day == %@", Date() as CVarArg), animation: .default)
    private var todayPlan: FetchedResults<DailyPlan>

    var body: some View {
        ZStack {
            BubblesBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: L2.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting()).font(L2.cap()).foregroundStyle(.secondary)
                        Text("Lamp & Light").font(L2.title())
                    }
                    .padding(.horizontal, L2.xl).padding(.top, L2.xl)

                    // Scripture card
                    VStack(alignment: .leading, spacing: L2.m) {
                        HStack {
                            Chip(text: todayRef, color: L2.green)
                            Spacer()
                            Button(action: { showWhy = true }) {
                                Image(systemName: "info.circle")
                            }
                            .accessibilityLabel(Text("Why this passage"))
                        }
                        Text(todayText)
                            .font(L2.body())
                            .lineSpacing(4)
                        Text("Text KJV Public Domain")
                            .font(L2.cap()).foregroundStyle(.secondary)
                    }
                    .glassCard()
                    .padding(.horizontal, L2.xl)

                    // Plan tiles
                    VStack(spacing: L2.m) {
                        tile(title: "Application", icon: "lightbulb", text: bits.application)
                        tile(title: "Prayer", icon: "hands.sparkles", text: bits.prayer)
                        tile(title: "Challenge", icon: "flame", text: bits.challenge)
                    }
                    .padding(.horizontal, L2.xl)

                    // Primary CTA
                    PrimaryPill(title: "Start devotion", systemImage: "sparkles") {
                        startDevotion()
                    }
                    .padding(.horizontal, L2.xl)

                    // Weekly progress
                    VStack(alignment: .leading, spacing: L2.s) {
                        Chip(text: "This week", color: .yellow)
                        ProgressView(value: weeklyDone, total: weeklyGoal).tint(L2.green)
                        Text("\(Int(weeklyDone)) of \(weeklyGoal) completed").font(L2.cap()).foregroundStyle(.secondary)
                    }
                    .glassCard()
                    .padding(.horizontal, L2.xl)
                    .padding(.bottom, L2.xxl)
                }
            }
        }
        .sheet(isPresented: $showWhy) {
            WhyThisPassageSheet(reference: todayRef, themes: [], reasons: reasons)
        }
    }

    // MARK: data plumbing
    @State private var showWhy = false
    private var plan: DailyPlan? { todayPlan.first }
    private var todayRef: String { plan?.scriptureRef ?? "John 1:1" }
    private var todayText: String { plan?.scriptureText ?? "In the beginning was the Word..." }
    private var bits: PlanBits { 
        if let plan = plan {
            return PlanBits(
                application: plan.application ?? "Live the truth today.",
                prayer: plan.prayer ?? "Lord, guide me.",
                challenge: plan.challenge ?? "Encourage one person.",
                crossrefs: plan.crossrefs ?? []
            )
        } else {
            return PlanBits(
                application: "Live the truth today.",
                prayer: "Lord, guide me.",
                challenge: "Encourage one person.",
                crossrefs: []
            )
        }
    }
    private var weeklyGoal: Double { 5 }
    private var weeklyDone: Double { 2 }
    private var reasons: [String] { ["Theme: Faith", "Cross-ref: Hebrews 11:1"] }

    private func startDevotion() { 
        // Navigate to reading flow or mark as started
        if let plan = plan {
            plan.status = "started"
            try? ctx.save()
        }
    }

    @ViewBuilder private func tile(title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: L2.s) {
            HStack(spacing: L2.s) {
                Image(systemName: icon).imageScale(.medium).foregroundStyle(.secondary)
                Chip(text: title)
                Spacer()
            }
            Text(text).font(L2.body())
        }
        .glassCard()
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
} 