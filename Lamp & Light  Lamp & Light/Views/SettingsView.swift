import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var profile: Profile?
    @State private var displayName = ""
    @State private var denomination = ""
    @State private var goals = ""
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        NavigationView {
            AppBackground {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Badge(text: "Profile Information", color: AppColor.primaryGreen)
                            
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Display Name")
                                        .font(AppFont.headline())
                                        .foregroundColor(AppColor.ink)
                                    TextField("Display Name", text: $displayName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(AppColor.softGreen.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Denomination")
                                        .font(AppFont.headline())
                                        .foregroundColor(AppColor.ink)
                                    TextField("Denomination", text: $denomination)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(AppColor.softGreen.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Spiritual Goals")
                                        .font(AppFont.headline())
                                        .foregroundColor(AppColor.ink)
                                    TextField("Spiritual Goals", text: $goals)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .lineLimit(3)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(AppColor.softGreen.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .card()
                        
                        // Data Management Section
                        VStack(alignment: .leading, spacing: 16) {
                            Badge(text: "Data Management", color: AppColor.sky)
                            
                            PillButton(title: "Export My Data", style: .secondary, systemImage: "square.and.arrow.up") {
                                exportUserData()
                            }
                        }
                        .card()
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            Badge(text: "About", color: AppColor.sunshine.opacity(0.5))
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Version")
                                        .font(AppFont.body())
                                        .foregroundColor(AppColor.ink)
                                    Spacer()
                                    Text("1.0.0")
                                        .font(AppFont.body())
                                        .foregroundColor(AppColor.slate)
                                }
                                
                                HStack {
                                    Text("Created")
                                        .font(AppFont.body())
                                        .foregroundColor(AppColor.ink)
                                    Spacer()
                                    if let profile = profile, let createdAt = profile.createdAt {
                                        Text(createdAt, style: .date)
                                            .font(AppFont.body())
                                            .foregroundColor(AppColor.slate)
                                    } else {
                                        Text("Unknown")
                                            .font(AppFont.body())
                                            .foregroundColor(AppColor.slate)
                                    }
                                }
                            }
                        }
                        .card()
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadProfile()
            }
            .onChange(of: displayName) { _, _ in saveProfile() }
            .onChange(of: denomination) { _, _ in saveProfile() }
            .onChange(of: goals) { _, _ in saveProfile() }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(activityItems: [data])
                }
            }
        }
    }
    
    private func loadProfile() {
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let profiles = try viewContext.fetch(fetchRequest)
            if let firstProfile = profiles.first {
                profile = firstProfile
                displayName = firstProfile.displayName ?? ""
                denomination = firstProfile.denomination ?? ""
                goals = firstProfile.goals ?? ""
            }
        } catch {
            print("Error loading profile: \(error)")
        }
    }
    
    private func saveProfile() {
        guard let profile = profile else { return }
        
        profile.displayName = displayName.isEmpty ? nil : displayName
        profile.denomination = denomination.isEmpty ? nil : denomination
        profile.goals = goals.isEmpty ? nil : goals
        
        do {
            try viewContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("Error saving profile: \(error)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    private func exportUserData() {
        guard let profile = profile else { return }
        
        var exportObject: [String: Any] = [:]
        
        // Profile data
        exportObject["profile"] = [
            "id": profile.id?.uuidString ?? "",
            "displayName": profile.displayName ?? "",
            "denomination": profile.denomination ?? "",
            "goals": profile.goals ?? "",
            "createdAt": (profile.createdAt?.timeIntervalSince1970 ?? 0) as Any
        ]
        
        // Daily Plans
        if let dailyPlans = profile.dailyPlans?.allObjects as? [DailyPlan] {
            let dailyPlansArray = dailyPlans.map { plan in
                [
                    "id": plan.id?.uuidString ?? "",
                    "scriptureRef": plan.scriptureRef ?? "",
                    "scriptureText": plan.scriptureText ?? "",
                    "application": plan.application ?? "",
                    "prayer": plan.prayer ?? "",
                    "challenge": plan.challenge ?? "",
                    "status": plan.status ?? "",
                    "day": (plan.day?.timeIntervalSince1970 ?? 0) as Any
                ] as [String: Any]
            }
            exportObject["dailyPlans"] = dailyPlansArray
        }
        
        // Weekly Recaps
        if let weeklyRecaps = profile.weeklyRecaps?.allObjects as? [WeeklyRecap] {
            let weeklyRecapsArray = weeklyRecaps.map { recap in
                [
                    "id": recap.id?.uuidString ?? "",
                    "recapMD": (recap.recapMD ?? "") as Any,
                    "weekStart": (recap.weekStart?.timeIntervalSince1970 ?? 0) as Any,
                    "metrics": recap.metrics ?? [:]
                ] as [String: Any]
            }
            exportObject["weeklyRecaps"] = weeklyRecapsArray
        }
        
        // Answered Prayers
        if let answeredPrayers = profile.answeredPrayers?.allObjects as? [AnsweredPrayer] {
            let answeredPrayersArray = answeredPrayers.map { prayer in
                [
                    "id": prayer.id?.uuidString ?? "",
                    "note": prayer.note ?? "",
                    "createdAt": (prayer.createdAt?.timeIntervalSince1970 ?? 0) as Any
                ] as [String: Any]
            }
            exportObject["answeredPrayers"] = answeredPrayersArray
        }
        
        // Convert to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportObject, options: .prettyPrinted)
            exportData = jsonData
            showingExportSheet = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            print("Error creating export data: \(error)")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 