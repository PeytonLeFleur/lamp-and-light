import os.log

enum Log {
    private static let logger = Logger(subsystem: "com.titanleadgen.lampandlight", category: "app")
    static func info(_ msg: String) { logger.log("\(msg, privacy: .public)") }
    static func error(_ msg: String) { logger.error("\(msg, privacy: .public)") }
} 