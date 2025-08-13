import SwiftUI
import CoreData

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var ctx
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<Profile>
    @State private var name = ""
    @State private var goal = "Grow in patience"
    @State private var weeklyGoal = 5
    @State private var notificationsOK = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppBackground {
            VStack(spacing: 14) {
                Text("Welcome").font(AppFont.title())
                
                VStack(alignment: .leading, spacing: 10) {
                    Badge(text: "Your Name")
                    TextField("Name", text: $name).textFieldStyle(.roundedBorder)
                }.card()

                VStack(alignment: .leading, spacing: 10) {
                    Badge(text: "Your Goal")
                    TextField("What do you want God to grow in you?", text: $goal).textFieldStyle(.roundedBorder)
                }.card()

                VStack(alignment: .leading, spacing: 10) {
                    Badge(text: "Weekly Challenges")
                    Stepper(value: $weeklyGoal, in: 1...14) {
                        Text("\(weeklyGoal) per week")
                    }
                }.card()

                PillButton(title: notificationsOK ? "Notifications On" : "Enable Daily Reminder", style: notificationsOK ? .secondary : .primary, systemImage: "bell.fill") {
                    Task {
                        notificationsOK = await Notifications.requestAuth()
                        if notificationsOK { Notifications.scheduleDaily() }
                    }
                }

                PillButton(title: "Start", style: .primary, systemImage: "arrow.right.circle.fill") {
                    saveAndClose()
                }

                Spacer(minLength: 6)
            }
        }
        .navigationTitle("Get Started")
    }

    private func saveAndClose() {
        let profile = profiles.first ?? Profile(context: ctx)
        if profiles.first == nil { profile.id = UUID(); profile.createdAt = Date() }
        profile.displayName = name.isEmpty ? "Friend" : name
        profile.goals = goal
        profile.weeklyGoal = Int16(weeklyGoal)
        try? ctx.save()
        UserDefaults.standard.set(true, forKey: "onboarded")
        dismiss()
    }
} 