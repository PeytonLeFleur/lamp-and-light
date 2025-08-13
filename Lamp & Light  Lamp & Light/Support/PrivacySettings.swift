import Foundation

enum PrivacySettings {
    private static let key = "privacy.analytics"
    static var analyticsEnabled: Bool {
        get { UserDefaults.standard.object(forKey: key) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
} 