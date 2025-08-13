import SwiftUI

enum AppColor {
    // Duolingo-like palette
    static let primaryGreen = Color(hex: "#22C55E")     // success green
    static let deepGreen    = Color(hex: "#16A34A")
    static let softGreen    = Color(hex: "#D1FAE5")
    static let sunshine     = Color(hex: "#FACC15")
    static let sky          = Color(hex: "#60A5FA")
    static let coral        = Color(hex: "#FB7185")
    static let ink          = Color(hex: "#0F172A")     // slate-900
    static let slate        = Color(hex: "#334155")     // slate-700
    static let mist         = Color(hex: "#F8FAFC")     // slate-50
    static let cardBG       = Color.white
}

enum AppFont {
    static func largeTitle(_ weight: Font.Weight = .bold) -> Font { .system(size: 34, weight: weight, design: .rounded) }
    static func title(_ weight: Font.Weight = .bold) -> Font { .system(size: 28, weight: weight, design: .rounded) }
    static func headline(_ weight: Font.Weight = .semibold) -> Font { .system(size: 20, weight: weight, design: .rounded) }
    static func body(_ weight: Font.Weight = .regular) -> Font { .system(size: 17, weight: weight, design: .rounded) }
    static func caption(_ weight: Font.Weight = .semibold) -> Font { .system(size: 13, weight: weight, design: .rounded) }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(AppColor.cardBG)
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
} 