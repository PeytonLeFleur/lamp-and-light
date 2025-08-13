import StoreKit
import UIKit

enum Ratings {
    static func maybeAsk(for event: String) {
        let defaults = UserDefaults.standard
        var count = defaults.integer(forKey: "rate.\(event)")
        count += 1
        defaults.set(count, forKey: "rate.\(event)")
        #if DEBUG
        return
        #endif
        if count == 2 || count == 5 {
            if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
} 