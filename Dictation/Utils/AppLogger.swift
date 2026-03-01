import Foundation
import os

// MARK: - AppLogger

/// os.Logger ベースのログユーティリティ。
enum AppLogger {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "app",
        category: "general"
    )

    static func debug(_ message: String) {
        logger.debug("\(message)")
    }

    static func info(_ message: String) {
        logger.info("\(message)")
    }

    static func warning(_ message: String) {
        logger.warning("\(message)")
    }

    static func error(_ message: String) {
        logger.error("\(message)")
    }
}
