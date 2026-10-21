import Foundation

/// Identifies "this package at this version", e.g. to remember what was
/// already announced. A new version of the same package is a new key.
public struct PackageKey: Sendable, Hashable, Codable {
    public let name: String
    public let kind: PackageKind
    public let version: String

    public init(name: String, kind: PackageKind, version: String) {
        self.name = name
        self.kind = kind
        self.version = version
    }
}

extension OutdatedPackage {
    public var key: PackageKey {
        PackageKey(name: name, kind: kind, version: currentVersion)
    }
}

/// Title and body of the "new updates" notification (German, shown to the user).
public struct NotificationText: Sendable, Equatable {
    public let title: String
    public let body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
    }
}

/// Decisions the app makes, as pure functions without side effects.
public enum Policies {
    /// An automatic check shows an error only after this many failures in a row.
    public static let failuresBeforeError = 3

    /// Is a check due? True if there was no successful check yet, the interval
    /// has passed, or `lastSuccess` lies in the future (the clock cannot be trusted).
    public static func isCheckDue(lastSuccess: Date?, interval: TimeInterval, now: Date) -> Bool {
        guard let lastSuccess else { return true }
        let elapsed = now.timeIntervalSince(lastSuccess)
        return elapsed < 0 || elapsed >= interval
    }

    /// Should a failed check be shown to the user? A manual check shows an error
    /// at once; an automatic one only after `failuresBeforeError` failures in a
    /// row. `consecutiveFailures` already includes the failure that just happened.
    public static func showsFailure(consecutiveFailures: Int, manual: Bool) -> Bool {
        manual || consecutiveFailures >= failuresBeforeError
    }

    /// Packages that should trigger a notification: not pinned and not announced
    /// yet in this version.
    public static func newlyOutdated(
        current: [OutdatedPackage],
        alreadyNotified: Set<PackageKey>
    ) -> [OutdatedPackage] {
        current.filter { !$0.pinned && !alreadyNotified.contains($0.key) }
    }

    /// Keeps only entries that are still outdated in exactly that version.
    public static func pruneNotified(
        _ notified: Set<PackageKey>,
        current: [OutdatedPackage]
    ) -> Set<PackageKey> {
        notified.intersection(current.map(\.key))
    }

    /// Number shown in the menu bar. Pinned packages do not count, because
    /// `brew upgrade` skips them.
    public static func badgeCount(_ packages: [OutdatedPackage]) -> Int {
        packages.filter { !$0.pinned }.count
    }

    /// Text of the notification. The title counts all upgradable packages
    /// (`badgeCount`); the body names the new ones: up to three names, then
    /// "und N weitere".
    public static func notificationText(
        newPackages: [OutdatedPackage],
        badgeCount: Int
    ) -> NotificationText {
        let title =
            badgeCount == 1
            ? "1 Homebrew-Update verfügbar"
            : "\(badgeCount) Homebrew-Updates verfügbar"

        let names = newPackages.map(\.name)
        let body: String
        switch names.count {
        case 0:
            body = ""
        case 1:
            body = names[0]
        case 2:
            body = "\(names[0]) und \(names[1])"
        case 3:
            body = "\(names[0]), \(names[1]) und \(names[2])"
        default:
            let rest = names.count - 3
            let restText = rest == 1 ? "1 weiteres" : "\(rest) weitere"
            body = "\(names[0]), \(names[1]), \(names[2]) und \(restText)"
        }
        return NotificationText(title: title, body: body)
    }
}