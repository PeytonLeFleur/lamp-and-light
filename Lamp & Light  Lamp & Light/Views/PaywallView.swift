import SwiftUI
import StoreKit
import SafariServices

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
                    Label("A calm, guided start to your day", systemImage: "sun.max.fill")
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
                PillButton(title: "Manage Subscription", style: .secondary, systemImage: "gear") {
                    openManageSubscriptions()
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
        var base: String
        if p.id.contains("monthly") { base = "Start Premium • \(price)/mo" }
        else if p.id.contains("yearly") { base = "Start Premium • \(price)/yr" }
        else { base = "Purchase \(price)" }

        if let offer = p.subscription?.introductoryOffer {
            let unit = offer.period.unit
            let value = offer.period.value
            let unitText: String = {
                switch unit {
                case .day: return value == 1 ? "day" : "days"
                case .week: return value == 1 ? "week" : "weeks"
                case .month: return value == 1 ? "month" : "months"
                case .year: return value == 1 ? "year" : "years"
                @unknown default: return "days"
                }
            }()
            return "\(base) • \(value) \(unitText) free"
        }
        return base
    }

    private func openManageSubscriptions() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    PaywallView()
} 