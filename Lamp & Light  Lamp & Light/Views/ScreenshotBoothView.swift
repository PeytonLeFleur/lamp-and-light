import SwiftUI
import UIKit

@available(iOS 17.0, *)
struct ScreenshotBoothView: View {
    @State private var showShare = false
    @State private var image: UIImage?

    var body: some View {
        AppBackground {
            ScrollView {
                VStack(spacing: 16) {
                    Badge(text: "Screenshot Booth")
                    sampleCard(title: "Today", subtitle: "Psalm 23:1-6", body: "The LORD is my shepherd...")
                    sampleCard(title: "Streak", subtitle: "7-day streak", body: "Keep going. Your daily plan awaits at dawn.")
                    sampleCard(title: "Weekly Recap", subtitle: "Highlights", body: "Prayers logged: 5\nChallenges done: 3\nTop themes: peace, trust")
                }
            }
        }
        .navigationTitle("Screenshots")
    }

    @ViewBuilder
    private func sampleCard(title: String, subtitle: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AppFont.title())
            Text(subtitle).font(AppFont.headline())
            Text(body).font(AppFont.body())
            PillButton(title: "Save Image", style: .secondary, systemImage: "square.and.arrow.down") {
                captureAndSave(title: title, subtitle: subtitle, body: body)
            }
        }
        .card()
    }

    private func captureAndSave(title: String, subtitle: String, body: String) {
        let view = VStack(alignment: .leading, spacing: 8) {
            Text(title).font(AppFont.title())
            Text(subtitle).font(AppFont.headline())
            Text(body).font(AppFont.body())
        }
        .padding(24)
        .frame(width: 1290, height: 2796)
        .background(.white)
        .cornerRadius(24)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        if let ui = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(ui, nil, nil, nil)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
} 