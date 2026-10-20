import AppKit
import BrewCheck
import Foundation

/// Errors that can happen while starting the upgrade in Terminal.
enum UpgradeLaunchError: Error {
    case cannotWriteScript
    case cannotOpenScript

    /// Short German text for the user interface.
    var userMessage: String {
        switch self {
        case .cannotWriteScript:
            return "Upgrade-Skript konnte nicht angelegt werden."
        case .cannotOpenScript:
            return "Terminal konnte nicht geöffnet werden."
        }
    }
}

/// Writes the temporary upgrade script and opens it (normally in Terminal).
@MainActor
enum UpgradeLauncher {
    static let scriptName = "thetap-upgrade.command"

    static func start(greedy: Bool) throws {
        let brew = try BrewLocator().locate()
        let content = UpgradeScript.content(brewPath: brew.path, greedy: greedy)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(scriptName)

        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755], ofItemAtPath: url.path)
        } catch {
            throw UpgradeLaunchError.cannotWriteScript
        }

        guard NSWorkspace.shared.open(url) else {
            throw UpgradeLaunchError.cannotOpenScript
        }
    }
}