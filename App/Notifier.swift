import BrewCheck
import Foundation
import UserNotifications
import os

/// Sends the "new updates" notification and remembers which packages were
/// already announced (`UserDefaults`, key `notifiedPackages`).
@MainActor
final class Notifier {
    static let notifiedKey = "notifiedPackages"

    private let defaults: UserDefaults
    private let logger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "notifications")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Asks macOS for permission to show alerts. Called once at startup;
    /// macOS only shows the dialog the first time.
    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert])
            logger.notice("Authorization \(granted ? "granted" : "denied", privacy: .public)")
        } catch {
            logger.error(
                "Authorization request failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Called after every successful check with the full list of outdated packages.
    /// Always updates the remembered set; sends a notification only if there are
    /// new packages and macOS allows notifications.
    func handle(_ packages: [OutdatedPackage]) async {
        // Bookkeeping first and without awaiting, so two checks cannot interleave here.
        let stored = loadNotified()
        let newPackages = Policies.newlyOutdated(current: packages, alreadyNotified: stored)
        let updated = Policies.pruneNotified(
            stored.union(newPackages.map(\.key)), current: packages)
        saveNotified(updated)

        guard !newPackages.isEmpty else {
            logger.notice("No new packages to announce (\(updated.count, privacy: .public) known)")
            return
        }

        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else {
            logger.notice(
                "Not sending: notifications are not allowed (\(newPackages.count, privacy: .public) new)"
            )
            return
        }

        let text = Policies.notificationText(
            newPackages: newPackages, badgeCount: Policies.badgeCount(packages))
        let content = UNMutableNotificationContent()
        content.title = text.title
        content.body = text.body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await center.add(request)
            logger.notice(
                "Notification sent: \(text.title, privacy: .public) | \(text.body, privacy: .public)")
        } catch {
            logger.error(
                "Sending the notification failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadNotified() -> Set<PackageKey> {
        guard let data = defaults.data(forKey: Self.notifiedKey) else { return [] }
        do {
            return Set(try JSONDecoder().decode([PackageKey].self, from: data))
        } catch {
            logger.error(
                "Could not read notifiedPackages: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    private func saveNotified(_ keys: Set<PackageKey>) {
        do {
            defaults.set(try JSONEncoder().encode(Array(keys)), forKey: Self.notifiedKey)
        } catch {
            logger.error(
                "Could not save notifiedPackages: \(error.localizedDescription, privacy: .public)")
        }
    }
}