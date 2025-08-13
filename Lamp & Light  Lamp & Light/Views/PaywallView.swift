import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var pm = PurchaseManager.shared

    var body: some View {
        AppBackground {
            VStack(spacing: 14) {
                Text("Lamp & Light Premium").font(AppFont.title())
                VStack(alignment: .leading, spacing: 8) {
                    Badge(text: "What you get")
                    Label("AI-personalized application, prayer, challenge", systemImage: "wand.and.stars")
                    Label("Weekly recaps and share cards", systemImage: "doc.text.image")
                    Label("Streak rewards and goal tracking", systemImage: "flame.fill")
                    Label("Future features included", systemImage: "sparkles")
                }.card()

                if pm.products.isEmpty {
                    Text("Loading plans…").font(AppFont.body())
                } else {
                    ForEach(pm.products, id: \.id) { p in
                        PillButton(title: buttonTitle(for: p), style: .primary, systemImage: "crown.fill") {
                            Task { await pm.buy(p) }
                        }
                        .accessibilityIdentifier("Start Premium")
                    }
                }

                PillButton(title: "Restore Purchases", style: .secondary, systemImage: "arrow.clockwise.circle") {
                    Task { await pm.restore() }
                }

                VStack(spacing: 6) {
                    NavigationLink("Terms of Use") { LegalView() }
                    NavigationLink("Privacy Policy") { LegalView() }
                    Text(pm.statusText).font(AppFont.caption()).foregroundColor(.secondary)
                }.padding(.top, 4)

                Spacer(minLength: 6)
            }
        }
        .task { await pm.load() }
        .navigationTitle("Upgrade")
    }

    private func buttonTitle(for p: Product) -> String {
        let price = p.displayPrice
        if p.id.contains("monthly") { return "Start Premium • \(price)/mo" }
        if p.id.contains("yearly") { return "Start Premium • \(price)/yr" }
        return "Purchase \(price)"
    }
}

#Preview {
    PaywallView()
} 