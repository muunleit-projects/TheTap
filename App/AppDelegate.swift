import AppKit
import UserNotifications
import os

/// Receives system events for the app. Owns the shared `AppState`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let state = AppState()

    private let network = NetworkMonitor()
    private var scheduler: Scheduler?

    private let logger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "upgrade")
    private let schedulerLogger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "scheduler")
    private let notificationLogger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "notifications")

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Must happen before the app finishes launching, so no notification
        // response is missed.
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        network.onChange = { [state, schedulerLogger] isOnline in
            schedulerLogger.notice("Network is \(isOnline ? "online" : "offline", privacy: .public)")
            state.networkChanged(isOnline: isOnline)
        }
        network.start()

        let scheduler = Scheduler(state: state)
        scheduler.start()
        self.scheduler = scheduler

        // The settings window reports a changed check interval through the state.
        state.onCheckIntervalChange = { [weak scheduler] in
            scheduler?.restartActivity()
        }

        state.notifier.registerCategories()
        Task { await state.notifier.requestAuthorization() }
    }

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

    // MARK: UNUserNotificationCenterDelegate

    /// Show notifications even while the app is active.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    /// The user chose an action on a notification.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier
        await handleNotificationAction(actionIdentifier)
    }

    private func handleNotificationAction(_ identifier: String) {
        guard identifier == Notifier.upgradeActionIdentifier else {
            notificationLogger.notice(
                "Notification action ignored: \(identifier, privacy: .public)")
            return
        }
        notificationLogger.notice("Notification action: upgrade (possible: \(self.state.canUpgrade, privacy: .public))")
        state.startUpgrade()
    }
}