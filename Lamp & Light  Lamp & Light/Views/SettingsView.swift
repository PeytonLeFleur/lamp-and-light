import SwiftUI
import CoreData
import UniformTypeIdentifiers
import UserNotifications

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<Profile>
    @State private var profile: Profile?
    @State private var displayName = ""
    @State private var denomination = ""
    @State private var goals = ""
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    @State private var notifHour = 6
    @State private var notifMinute = 0
    @State private var exportURL: URL?
    @State private var showFileShare = false
    @State private var presentPaywall = false
    
    var body: some View {
        NavigationView {
            AppBackground {
                ScrollView {
                    VStack(spacing: 20) {
                        // Subscription card
                        VStack(alignment: .leading, spacing: 10) {
                            Badge(text: "Subscription")
                            Text(PurchaseManager.shared.isPremium ? "Premium active" : "Free").font(AppFont.body())
                            HStack(spacing: 12) {
                                PillButton(title: "Manage", style: .secondary, systemImage: "crown.fill") { presentPaywall = true }
                                PillButton(title: "Restore", style: .secondary, systemImage: "arrow.clockwise") { Task { await PurchaseManager.shared.restore() } }
                            }
                        }.card()
                        
                        // About & Legal
                        VStack(alignment: .leading, spacing: 10) {
                            Badge(text: "About & Legal")
                            NavigationLink("About Lamp & Light") { AboutView() }
                            NavigationLink("Terms, Privacy, Disclaimer") { LegalView() }
                        }.card()
                        
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
                        
                        // Weekly Goals Section
                        VStack(alignment: .leading, spacing: 16) {
                            Badge(text: "Weekly Goals", color: AppColor.deepGreen)
                            
                            if let profile = profile {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Weekly Challenge Goal")
                                            .font(AppFont.body())
                                            .foregroundColor(AppColor.ink)
                                        Spacer()
                                        Text("\(profile.weeklyGoal)")
                                            .font(AppFont.headline())
                                            .foregroundColor(AppColor.primaryGreen)
                                    }
                                    
                                    Stepper(
                                        value: Binding(
                                            get: { Int(profile.weeklyGoal) },
                                            set: { 
                                                profile.weeklyGoal = Int16($0)
                                                try? viewContext.save()
                                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            }
                                        ),
                                        in: 1...14
                                    ) {
                                        Text("Adjust weekly goal")
                                            .font(AppFont.caption())
                                            .foregroundColor(AppColor.slate)
                                    }
                                }
                            }
                        }
                        .card()
                        
                        // Daily Reminder Section
                        VStack(alignment: .leading, spacing: 10) {
                            Badge(text: "Daily Reminder", color: AppColor.sky)
                            Stepper(value: $notifHour, in: 0...23) { Text("Hour: \(notifHour)") }
                            Stepper(value: $notifMinute, in: 0...55, step: 5) { Text("Minute: \(notifMinute)") }
                            PillButton(title: "Save Reminder Time", style: .secondary, systemImage: "bell.badge.fill") {
                                Notifications.scheduleDaily(hour: notifHour, minute: notifMinute)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                        }
                        .card()
                        
                        // Data Management Section
                        VStack(alignment: .leading, spacing: 16) {
                            Badge(text: "Data Management", color: AppColor.sky)
                            
                            VStack(spacing: 12) {
                                PillButton(title: "Export My Data (File)", style: .secondary, systemImage: "square.and.arrow.up.on.square") {
                                    guard let p = profile else { return }
                                    do {
                                        exportURL = try BackupService.exportAll(context: viewContext, profile: p)
                                        showFileShare = true
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    } catch {
                                        Log.error("Export error \(error.localizedDescription)")
                                    }
                                }
                                .sheet(isPresented: $showFileShare) {
                                    if let url = exportURL { ShareLink(item: url) }
                                }
                                
                                PillButton(title: "Export My Data (Inline JSON)", style: .secondary, systemImage: "square.and.arrow.up") {
                                    exportUserData()
                                }
                                
                                if let profile = profile, profile.streakCount > 0 {
                                    PillButton(title: "Share My Streak", style: .primary, systemImage: "heart.fill") {
                                        shareStreak(profile: profile)
                                    }
                                }
                            }
                        }
                        .card()
                        
                        // About / Paywall
                        VStack(alignment: .leading, spacing: 16) {
                            Badge(text: "About", color: AppColor.sunshine.opacity(0.5))
                            
                            VStack(spacing: 12) {
                                NavigationLink(destination: PaywallView()) {
                                    HStack {
                                        Image(systemName: "lock.circle")
                                        Text("Upgrade (Placeholder)")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .font(AppFont.body())
                                    .foregroundColor(AppColor.ink)
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
            .onAppear { loadProfile() }
            .onChange(of: displayName) { _, _ in saveProfile() }
            .onChange(of: denomination) { _, _ in saveProfile() }
            .onChange(of: goals) { _, _ in saveProfile() }
            .sheet(isPresented: $showingExportSheet) { if let data = exportData { ShareSheet(activityItems: [data]) } }
            .sheet(isPresented: $showingShareSheet) { if let image = shareImage { ShareSheet(activityItems: [image]) } }
            .sheet(isPresented: $presentPaywall) { PaywallView() }
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
    
    private func shareStreak(profile: Profile) {
        // Get the last completed plan's scripture reference
        let fetchRequest: NSFetchRequest<DailyPlan> = DailyPlan.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profile == %@ AND status == %@", profile, "done")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DailyPlan.day, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        let verse = (try? viewContext.fetch(fetchRequest).first?.scriptureRef) ?? "Psalm 46:1-3"
        
        // Create the share card
        let shareCard = ShareCardView(
            name: profile.displayName ?? "Friend",
            days: Int(profile.streakCount),
            verse: verse
        )
        
        // Render to image
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
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