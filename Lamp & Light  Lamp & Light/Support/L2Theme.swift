import SwiftUI

enum L2 {
    // Spacing
    static let xs: CGFloat = 6, s: CGFloat = 10, m: CGFloat = 14, l: CGFloat = 18, xl: CGFloat = 24, xxl: CGFloat = 32
    // Radius
    static let rSm: CGFloat = 14, rMd: CGFloat = 20, rLg: CGFloat = 28
    // Fonts
    static func title() -> Font { .system(.largeTitle, design: .rounded).weight(.bold) }
    static func h() -> Font { .system(.title3, design: .rounded).weight(.semibold) }
    static func body() -> Font { .system(.body, design: .rounded) }
    static func cap() -> Font { .system(.footnote, design: .rounded) }

    // Brand colors from your palette
    static let green = Color(.systemGreen)
    static let teal  = Color(.systemTeal)
    static let sky   = Color(red: 0.74, green: 0.90, blue: 0.96)
    static let blush = Color(red: 0.92, green: 0.78, blue: 0.90)
}

extension View {
    func glassCard() -> some View {
        self
            .padding(L2.l)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: L2.rMd, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: L2.rMd, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
} 