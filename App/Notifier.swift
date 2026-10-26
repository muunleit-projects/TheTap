import BrewCheck
import Foundation
import UserNotifications
import os

/// Sends the "new updates" notification and remembers which packages were
/// already announced (`UserDefaults`, key `notifiedPackages`).
@MainActor
final class Notifier {
    static let notifiedKey = "notifiedPackages"

    /// `UserDefaults` key for the "send notifications" switch in the settings.
    nonisolated static let enabledKey = "notificationsEnabled"

    /// Category of the "new updates" notification; it carries the upgrade action.
    nonisolated static let categoryIdentifier = "thetap.updates"
    /// Identifier of the "Alles aktualisieren" action.
    nonisolated static let upgradeActionIdentifier = "thetap.upgrade"

    private let defaults: UserDefaults
    private let logger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "notifications")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether the user switched notifications on in the settings. Default: on.
    var isEnabled: Bool {
        defaults.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// Whether macOS currently allows this app to show notifications.
    func isAllowedBySystem() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings()
            .authorizationStatus
        return status == .authorized || status == .provisional
    }

    /// Registers the notification category with its action. Called once at startup.
    func registerCategories() {
        let upgrade = UNNotificationAction(
            identifier: Self.upgradeActionIdentifier,
            title: "Alles aktualisieren",
            options: [])
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [upgrade],
            intentIdentifiers: [],
            options: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        logger.notice("Notification category registered")
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
    /// new packages, the settings allow it and macOS allows notifications.
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

        guard isEnabled else {
            logger.notice(
                "Not sending: notifications are switched off in the settings (\(newPackages.count, privacy: .public) new)"
            )
            return
        }

        guard await isAllowedBySystem() else {
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
        content.categoryIdentifier = Self.categoryIdentifier
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
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