#if canImport(Sentry)
import Sentry

enum CrashReporting {
    static func start() {
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String, dsn.isEmpty == false else { return }
        SentrySDK.start { opts in
            opts.dsn = dsn
            opts.tracesSampleRate = 0.2
            opts.enableSwizzling = true
        }
    }
}
#else
import Foundation

enum CrashReporting {
    static func start() { /* no-op if Sentry not available */ }
}
#endif 