import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        AppBackground {
            VStack(spacing: 20) {
                Text("Lamp & Light Plus")
                    .font(AppFont.title())
                Text("Support development and unlock upcoming features like deeper insights, widgets, and more.")
                    .font(AppFont.body())
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColor.slate)
                    .padding(.horizontal)
                PillButton(title: "Continue Free", style: .secondary, systemImage: "arrow.right") {
                    dismiss()
                }
                Spacer()
            }
        }
        .navigationTitle("Upgrade")
    }
}

#Preview {
    PaywallView()
} 