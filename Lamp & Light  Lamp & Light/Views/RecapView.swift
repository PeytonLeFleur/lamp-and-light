import SwiftUI
import CoreData

struct RecapView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<Profile>
    @State private var recap: WeeklyRecap?
    @State private var presentPaywall = false

    var body: some View {
        AppBackground {
            VStack(spacing: 14) {
                Badge(text: "Weekly Recap", color: AppColor.sunshine)
                
                if let recap = recap {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text((recap.recapMD ?? "") + "\n\nText KJV Public Domain")
                                .font(AppFont.body())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }
                        .card()
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 60))
                            .foregroundColor(AppColor.slate.opacity(0.3))
                        
                        Text("No recap yet this week")
                            .font(AppFont.headline())
                            .foregroundColor(AppColor.ink)
                        
                        Text("Generate a weekly recap to see your spiritual journey highlights")
                            .font(AppFont.body())
                            .foregroundColor(AppColor.slate)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        PillButton(title: "Generate Recap", style: .primary, systemImage: "arrow.triangle.2.circlepath.circle.fill") {
                            FeatureGate.requirePremium(isPremium: PurchaseManager.shared.isPremium, action: {
                                generate()
                            }, showPaywall: {
                                presentPaywall = true
                            })
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Recap")
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
    RecapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 