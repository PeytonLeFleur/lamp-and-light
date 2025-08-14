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
    @State private var exportStatus: String? = nil
    @State private var exportError: String? = nil
    
    var body: some View {
        AppScaffold(title: "Settings") {
            // Subscription
            VStack(alignment: .leading, spacing: 10) {
                Badge(text: "Subscription")
                Text(PurchaseManager.shared.isPremium ? "Premium active" : "Free").font(AppFontV3.body())
                HStack(spacing: 12) {
                    PillButton(title: "Manage", style: .secondary, systemImage: "crown.fill") { presentPaywall = true }
                    PillButton(title: "Restore", style: .secondary, systemImage: "arrow.clockwise") { Task { await PurchaseManager.shared.restore() } }
                }
            }.card()
            
            // Privacy
            VStack(alignment: .leading, spacing: 10) {
                Badge(text: "Privacy")
                Toggle("Allow anonymous analytics", isOn: Binding(
                    get: { PrivacySettings.analyticsEnabled },
                    set: { PrivacySettings.analyticsEnabled = $0 }
                ))
                .tint(S.mint)
                Text("Helps improve the app. No personal text is sent.").font(AppFontV3.caption()).foregroundStyle(.secondary)
            }.card()
            
            // About & Legal
            VStack(alignment: .leading, spacing: 10) {
                Badge(text: "About & Legal")
                NavigationLink { AboutView() } label: { IconRow(icon: "info.circle", title: "About Lamp & Light") }
                NavigationLink { LegalView() } label: { IconRow(icon: "doc.text", title: "Terms, Privacy, Disclaimer") }
                if #available(iOS 17.0, *) { NavigationLink { ScreenshotBoothView() } label: { IconRow(icon: "camera", title: "Screenshot Booth") } }
                PillButton(title: "Share Lamp & Light", style: .secondary, systemImage: "square.and.arrow.up") {
                    let text = "One passage, one prayer, one small challenge. Try Lamp & Light."
                    let items: [Any] = [text]
                    let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first?.present(av, animated: true)
                }
            }.card()
            
            // Profile
            VStack(alignment: .leading, spacing: 16) {
                Badge(text: "Profile Information")
                TextField("Display Name", text: $displayName).textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Denomination", text: $denomination).textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Spiritual Goals", text: $goals).textFieldStyle(RoundedBorderTextFieldStyle())
            }.card()
            
            // Weekly Goal
            VStack(alignment: .leading, spacing: 12) {
                Badge(text: "Weekly Goals")
                if let profile = profile {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Weekly Challenge Goal").font(AppFontV3.body()); Spacer(); Text("\(profile.weeklyGoal)").font(AppFontV3.h2())
                        }
                        Stepper(value: Binding(get: { Int(profile.weeklyGoal) }, set: { profile.weeklyGoal = Int16($0); try? viewContext.save(); UINotificationFeedbackGenerator().notificationOccurred(.success) }), in: 1...14) { Text("Adjust weekly goal").font(AppFontV3.caption()).foregroundStyle(.secondary) }
                    }
                }
            }.card()
            
            // Daily Reminder
            VStack(alignment: .leading, spacing: 10) {
                Badge(text: "Daily Reminder")
                Stepper(value: $notifHour, in: 0...23) { Text("Hour: \(notifHour)") }
                Stepper(value: $notifMinute, in: 0...55, step: 5) { Text("Minute: \(notifMinute)") }
                PillButton(title: "Save Reminder Time", style: .secondary, systemImage: "bell.badge.fill") {
                    Notifications.scheduleDaily(hour: notifHour, minute: notifMinute)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }.card()
            
            // Data
            VStack(alignment: .leading, spacing: 16) {
                Badge(text: "Data Management")
                PillButton(title: "Export My Data (File)", style: .secondary, systemImage: "square.and.arrow.up.on.square") {
                    guard let p = profile else { return }
                    do {
                        exportURL = try BackupService.exportAll(context: viewContext, profile: p)
                        showFileShare = true; exportStatus = "Exported to file successfully."; exportError = nil
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } catch { exportError = error.localizedDescription; exportStatus = nil; Log.error("Export error \(error.localizedDescription)") }
                }
                .sheet(isPresented: $showFileShare) { if let url = exportURL { ShareLink(item: url) } }
                PillButton(title: "Export My Data (Inline JSON)", style: .secondary, systemImage: "square.and.arrow.up") { exportUserData() }
                if let status = exportStatus { Text(status).font(AppFontV3.caption()).foregroundStyle(.secondary) }
                if let err = exportError { ErrorCard(text: "Export failed: \(err)") }
            }.card()
        }
        .sheet(isPresented: $presentPaywall) { PaywallView() }
        .onAppear { loadProfile() }
        .onChange(of: displayName) { _, _ in saveProfile() }
        .onChange(of: denomination) { _, _ in saveProfile() }
        .onChange(of: goals) { _, _ in saveProfile() }
    }
    
    private func loadProfile() {
        let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest(); fetchRequest.fetchLimit = 1
        do { let profiles = try viewContext.fetch(fetchRequest); if let firstProfile = profiles.first { profile = firstProfile; displayName = firstProfile.displayName ?? ""; denomination = firstProfile.denomination ?? ""; goals = firstProfile.goals ?? "" } } catch { print("Error loading profile: \(error)") }
    }
    
    private func saveProfile() {
        guard let profile = profile else { return }
        profile.displayName = displayName.isEmpty ? nil : displayName
        profile.denomination = denomination.isEmpty ? nil : denomination
        profile.goals = goals.isEmpty ? nil : goals
        do { try viewContext.save(); UINotificationFeedbackGenerator().notificationOccurred(.success) } catch { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    }
    
    // exportUserData and shareStreak remain as before
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
		UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
	}
	func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

#Preview { SettingsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext) } 