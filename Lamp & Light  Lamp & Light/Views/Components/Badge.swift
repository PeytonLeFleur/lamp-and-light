import SwiftUI

struct Badge: View {
    let text: String
    var color: Color = AppColor.softGreen
    var body: some View {
        Text(text.uppercased())
            .font(AppFont.caption(.bold))
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(color.opacity(0.6))
            .foregroundColor(AppColor.ink)
            .clipShape(Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(text))
            .accessibilityAddTraits(.isStaticText)
    }
} 