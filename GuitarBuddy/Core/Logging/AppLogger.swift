import Foundation
import os

/// Centralized `os.Logger` instances, one per feature, sharing a common subsystem.
/// View unified logs in Console.app by filtering on the subsystem, or per-category.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.guitarbuddy.app"

    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let tuner = Logger(subsystem: subsystem, category: "tuner")
    static let keyFinder = Logger(subsystem: subsystem, category: "keyFinder")
    static let humMode = Logger(subsystem: subsystem, category: "humMode")
    static let transcribe = Logger(subsystem: subsystem, category: "transcribe")
}
