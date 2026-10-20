import Foundation

/// Whether a package is a command-line formula or a GUI app (cask).
public enum PackageKind: String, Sendable, Codable {
    case formula
    case cask
}

/// One outdated Homebrew package.
public struct OutdatedPackage: Sendable, Hashable, Codable {
    public let name: String
    public let kind: PackageKind
    public let installedVersions: [String]
    public let currentVersion: String
    public let pinned: Bool

    public init(
        name: String,
        kind: PackageKind,
        installedVersions: [String],
        currentVersion: String,
        pinned: Bool
    ) {
        self.name = name
        self.kind = kind
        self.installedVersions = installedVersions
        self.currentVersion = currentVersion
        self.pinned = pinned
    }
}

/// Everything that can go wrong while checking for updates.
public enum BrewCheckError: Error, Sendable {
    case brewNotFound(searched: [String])
    case commandFailed(command: [String], exitCode: Int32, output: String)
    case timedOut(command: [String], after: Duration)
    case invalidJSON(String)
    case cancelled
}