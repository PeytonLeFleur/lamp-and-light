import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .imageScale(.large)
            Text(title).font(AppFont.headline())
            Text(message).font(AppFont.body()).foregroundColor(.secondary).multilineTextAlignment(.center)
            if let actionTitle, let action {
                PillButton(title: actionTitle, style: .secondary, systemImage: "plus.circle", action: action)
                    .padding(.top, 6)
            }
        }
        .card()
    }
} 