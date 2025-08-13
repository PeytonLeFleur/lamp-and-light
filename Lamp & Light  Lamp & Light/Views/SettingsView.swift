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
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Display Name", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Denomination", text: $denomination)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Spiritual Goals", text: $goals)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3)
                }
                
                Section(header: Text("Data Management")) {
                    Button("Export My Data") {
                        exportUserData()
                    }
                    .foregroundColor(.accentColor)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        if let profile = profile, let createdAt = profile.createdAt {
                            Text(createdAt, style: .date)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unknown")
                                .foregroundColor(.secondary)
                        }
                    }
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
        } catch {
            print("Error saving profile: \(error)")
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
        
        // Entries
        if let entries = profile.entries?.allObjects as? [Entry] {
            exportObject["entries"] = entries.map { entry in
                [
                    "id": entry.id?.uuidString ?? "",
                    "kind": entry.kind ?? "",
                    "content": entry.content ?? "",
                    "emotion": entry.emotion ?? "",
                    "tags": entry.tags ?? [],
                    "createdAt": entry.createdAt?.timeIntervalSince1970 ?? 0
                ]
            }
        }
        
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
        } catch {
            print("Error creating export data: \(error)")
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