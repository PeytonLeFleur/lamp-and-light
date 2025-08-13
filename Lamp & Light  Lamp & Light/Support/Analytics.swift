#if canImport(TelemetryClient)
import Foundation
import TelemetryClient

enum Analytics {
    static func start() {
        if let appID = Bundle.main.object(forInfoDictionaryKey: "TELEMETRY_APP_ID") as? String, appID.isEmpty == false {
            TelemetryManager.initialize(with: appID)
        }
    }
    static func track(_ event: String, _ payload: [String: String] = [:]) {
        guard PrivacySettings.analyticsEnabled else { return }
        TelemetryManager.send(event: event, with: payload)
    }
}
#else
import Foundation

enum Analytics {
    static func start() { }
    static func track(_ event: String, _ payload: [String: String] = [:]) { }
}
#endif 