import SwiftUI
import CoreData

struct RecapView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<Profile>
    @State private var recap: WeeklyRecap?
    @State private var presentPaywall = false

    var body: some View {
        AppScaffold(title: "Recap", subtitle: "Your week at a glance") {
            Badge(text: "Weekly Recap", color: .yellow)
            if let recap = recap {
                VStack(alignment: .leading, spacing: 16) {
                    Text((recap.recapMD ?? "") + "\n\nText KJV Public Domain")
                        .font(AppFontV3.body())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                .card()
            } else {
                let isSunday = Calendar.current.component(.weekday, from: Date()) == 1
                if isSunday {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.image").font(.system(size: 60)).foregroundStyle(.secondary)
                        Text("No recap yet this week").font(AppFontV3.h2())
                        Text("Generate a weekly recap to see your spiritual journey highlights").font(AppFontV3.body()).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                        PillButton(title: "Generate Recap", style: .primary, systemImage: "arrow.triangle.2.circlepath.circle.fill") {
                            FeatureGate.requirePremium(isPremium: PurchaseManager.shared.isPremium, action: { generate() }, showPaywall: { presentPaywall = true })
                        }
                    }
                    .card()
                } else {
                    EmptyStateView(title: "No recap yet", message: "Your weekly recap appears on Sunday.")
                        .card()
                }
            }
        }
        .task { loadLatest() }
        .sheet(isPresented: $presentPaywall) { PaywallView() }
    }

    private func loadLatest() {
        guard let profile = profiles.first else { return }
        let req: NSFetchRequest<WeeklyRecap> = WeeklyRecap.fetchRequest()
        req.predicate = NSPredicate(format: "profile == %@", profile)
        req.sortDescriptors = [NSSortDescriptor(key: "weekStart", ascending: false)]
        recap = try? context.fetch(req).first
    }

    private func generate() {
        guard let profile = profiles.first else { return }
        do {
            recap = try RecapService.generateThisWeek(context: context, profile: profile)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("Recap error", error.localizedDescription)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

#Preview {
    RecapView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 