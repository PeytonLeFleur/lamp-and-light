import SwiftUI
import CoreData
import UIKit

struct AboutView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var profiles: FetchedResults<Profile>
    @State private var showingLegal = false

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lamp & Light").font(AppFont.title())
                        Text("Version \(versionString)").font(AppFont.body()).foregroundColor(AppColor.slate)
                        Text("Text KJV Public Domain").font(AppFont.caption()).foregroundColor(.secondary)
                    }.card()

                    VStack(alignment: .leading, spacing: 10) {
                        Badge(text: "Legal")
                        NavigationLink("View Terms, Privacy, and Disclaimer") { LegalView() }
                    }.card()

                    VStack(alignment: .leading, spacing: 10) {
                        Badge(text: "Support")
                        PillButton(title: "Contact Support", style: .secondary, systemImage: "envelope.fill") {
                            openSupportEmail()
                        }
                        PillButton(title: "Delete My Data On This Device", style: .danger, systemImage: "trash.fill") {
                            confirmDelete()
                        }
                    }.card()

                    Spacer(minLength: 20)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("About")
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return "\(v) (\(b))"
    }

    private func openSupportEmail() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        let sys = UIDevice.current.systemVersion
        let locale = Locale.current.identifier
        let subject = "Lamp & Light Support"
        let body = """
        Please describe your issue here.

        Version \(version) (\(build))
        iOS \(sys)
        Locale \(locale)
        """
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:support@lampandlight.app?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }

    private func confirmDelete() {
        // Simple destructive delete: wipe all objects
        let types: [NSFetchRequest<NSFetchRequestResult>] = [Profile.fetchRequest(), Entry.fetchRequest(), DailyPlan.fetchRequest(), WeeklyRecap.fetchRequest(), AnsweredPrayer.fetchRequest()]
        types.forEach { req in
            let batch = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? context.execute(batch)
        }
        try? context.save()
        // Restart scene
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let delegate = scene.delegate as? UIWindowSceneDelegate,
           let window = scene.windows.first {
            window.rootViewController = UIHostingController(rootView: AboutView().environment(\.managedObjectContext, context))
            window.makeKeyAndVisible()
        }
    }
} 