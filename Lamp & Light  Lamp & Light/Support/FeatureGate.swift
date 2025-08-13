import Foundation

enum FeatureGate {
    static func requirePremium(isPremium: Bool, action: () -> Void, showPaywall: () -> Void) {
        if isPremium { action() } else { showPaywall() }
    }
} 