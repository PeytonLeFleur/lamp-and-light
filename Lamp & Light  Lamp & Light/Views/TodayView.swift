import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var planService = PlanService()
    @State private var dailyPlan: DailyPlan?
    @State private var profile: Profile?
    @State private var showingScriptureExpanded = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let plan = dailyPlan {
                        // Scripture Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Today's Scripture")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: { showingScriptureExpanded.toggle() }) {
                                    Image(systemName: showingScriptureExpanded ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            
                            Text(plan.scriptureRef ?? "")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                            
                            if showingScriptureExpanded {
                                Text(plan.scriptureText ?? "")
                                    .font(.body)
                                    .lineLimit(nil)
                                    .padding(.top, 8)
                                
                                if let crossrefs = plan.crossrefs, !crossrefs.isEmpty {
                                    Text("Cross-references: \(crossrefs.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Application Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Life Application")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(plan.application ?? "")
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Prayer Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Prayer")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Button(action: copyPrayer) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            
                            Text(plan.prayer ?? "")
                                .font(.body)
                                .italic()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Challenge Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Kingdom Challenge")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(plan.challenge ?? "")
                                .font(.body)
                            
                            HStack {
                                Button("Done") {
                                    markChallengeComplete(plan)
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Skip") {
                                    markChallengeSkipped(plan)
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        ProgressView("Loading today's plan...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .onAppear {
                loadProfileAndPlan()
            }
        }
    }
    
    private func loadProfileAndPlan() {
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let profiles = try viewContext.fetch(fetchRequest)
            if let firstProfile = profiles.first {
                profile = firstProfile
                dailyPlan = planService.generateTodayPlan(context: viewContext, profile: firstProfile)
                
                // Save the context if a new plan was created
                if dailyPlan?.objectID.isTemporaryID == true {
                    try viewContext.save()
                }
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func copyPrayer() {
        if let prayer = dailyPlan?.prayer {
            UIPasteboard.general.string = prayer
        }
    }
    
    private func markChallengeComplete(_ plan: DailyPlan) {
        plan.status = "completed"
        try? viewContext.save()
    }
    
    private func markChallengeSkipped(_ plan: DailyPlan) {
        plan.status = "skipped"
        try? viewContext.save()
    }
}

#Preview {
    TodayView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 