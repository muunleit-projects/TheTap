import Foundation

/// Finds the brew executable: first in PATH, then in the standard Homebrew
/// locations (PATH is very short for apps started from Finder or at login).
public struct BrewLocator: Sendable {
    public static let standardPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]

    private let path: String
    private let isExecutable: @Sendable (String) -> Bool

    public init(
        path: String = ProcessInfo.processInfo.environment["PATH"] ?? "",
        isExecutable: @escaping @Sendable (String) -> Bool = {
            FileManager.default.isExecutableFile(atPath: $0)
        }
    ) {
        self.path = path
        self.isExecutable = isExecutable
    }

    /// Returns the first existing, executable brew, or throws
    /// `BrewCheckError.brewNotFound` listing every path that was checked.
    public func locate() throws -> URL {
        let candidates = candidatePaths()

        for candidate in candidates where isExecutable(candidate) {
            return URL(fileURLWithPath: candidate)
        }

        throw BrewCheckError.brewNotFound(searched: candidates)
    }

    private func candidatePaths() -> [String] {
        let fromPath = path
            .split(separator: ":", omittingEmptySubsequences: true)
            .map { URL(fileURLWithPath: String($0)).appendingPathComponent("brew").path }

        var seen = Set<String>()

        return (fromPath + Self.standardPaths).filter { seen.insert($0).inserted }
    }
}