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

/// Decisions the app makes, as pure functions without side effects.
public enum Policies {
    /// Is a check due? True if there was no successful check yet, the interval
    /// has passed, or `lastSuccess` lies in the future (the clock cannot be trusted).
    public static func isCheckDue(lastSuccess: Date?, interval: TimeInterval, now: Date) -> Bool {
        guard let lastSuccess else { return true }
        let elapsed = now.timeIntervalSince(lastSuccess)
        return elapsed < 0 || elapsed >= interval
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
}