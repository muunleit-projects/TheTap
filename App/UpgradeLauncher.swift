import AppKit
import BrewCheck
import Foundation

/// Errors that can happen while starting the upgrade in Terminal.
/// The associated values are only for the log file; the user sees `userMessage`.
enum UpgradeLaunchError: Error, CustomStringConvertible {
    case cannotWriteScript(path: String, reason: String)
    case cannotOpenScript(path: String)

    /// Short German text for the user interface.
    var userMessage: String {
        switch self {
        case .cannotWriteScript:
            return "Upgrade-Skript konnte nicht angelegt werden."
        case .cannotOpenScript:
            return "Terminal konnte nicht geöffnet werden."
        }
    }

    /// English details for the log file. `AppState` writes `"\(error)"`,
    /// which uses this text.
    var description: String {
        switch self {
        case .cannotWriteScript(let path, let reason):
            return "Could not write the upgrade script to \(path): \(reason)"
        case .cannotOpenScript(let path):
            return "NSWorkspace could not open \(path)"
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
            throw UpgradeLaunchError.cannotWriteScript(
                path: url.path, reason: error.localizedDescription)
        }

        guard NSWorkspace.shared.open(url) else {
            throw UpgradeLaunchError.cannotOpenScript(path: url.path)
        }
    }
}