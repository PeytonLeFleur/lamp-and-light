import SwiftUI

struct PillButton: View {
    enum Style { case primary, secondary, danger }
    let title: String
    var style: Style = .primary
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let s = systemImage { Image(systemName: s).imageScale(.medium) }
                Text(title).font(AppFont.headline())
            }
            .padding(.vertical, 14).padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(background)
            .clipShape(Capsule())
            .shadow(color: background.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text({
            switch style {
            case .primary: return "Primary action"
            case .secondary: return "Secondary action"
            case .danger: return "Danger action"
            }
        }()))
        .contentShape(Rectangle())
    }

    private var background: Color {
        switch style {
        case .primary: return AppColor.primaryGreen
        case .secondary: return AppColor.sky
        case .danger: return AppColor.coral
        }
    }
} 