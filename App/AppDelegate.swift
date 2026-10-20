import AppKit
import os

/// Receives system events for the app. Owns the shared `AppState`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()

    private let logger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "upgrade")

    /// Handles `thetap://recheck`, which the upgrade script opens when brew is done.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "thetap", url.host == "recheck" {
                logger.notice("Recheck requested via URL")
                Task { await state.recheckAfterUpgrade() }
            } else {
                logger.notice("Ignoring unknown URL: \(url.absoluteString, privacy: .public)")
            }
        }
    }
}