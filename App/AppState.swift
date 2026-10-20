import BrewCheck
import Foundation
import Observation

/// Where the app currently stands. Drives the menu bar icon and the panel header.
enum CheckPhase: Equatable {
    case notChecked
    case checking
    case upToDate
    case updatesAvailable
    case offline
    case failed
}

/// Single source of truth for the user interface.
@MainActor
@Observable
final class AppState {
    private(set) var phase: CheckPhase = .notChecked
    private(set) var packages: [OutdatedPackage] = []
    private(set) var lastSuccess: Date?
    private(set) var lastErrorMessage: String?
    private(set) var consecutiveFailures = 0
    private(set) var upgradeRunning = false

    private let checker = BrewChecker()

    /// Number shown next to the menu bar icon (pinned packages do not count).
    var badgeCount: Int { Policies.badgeCount(packages) }

    var isChecking: Bool { phase == .checking }

    /// Header text of the panel.
    var statusText: String {
        switch phase {
        case .notChecked:
            return "Noch nicht geprüft"
        case .checking:
            return "Prüfe auf Updates …"
        case .upToDate:
            return "Alles aktuell"
        case .updatesAvailable:
            return badgeCount == 1 ? "1 Update verfügbar" : "\(badgeCount) Updates verfügbar"
        case .offline:
            return "Offline – Prüfung folgt, sobald das Netz da ist"
        case .failed:
            return lastErrorMessage ?? "Prüfung fehlgeschlagen"
        }
    }

    /// Runs `brew update` and `brew outdated`. Ignored while a check is running.
    func checkNow() async {
        guard phase != .checking else { return }
        phase = .checking
        lastErrorMessage = nil
        do {
            let result = try await checker.outdated()
            packages = result
            lastSuccess = Date()
            consecutiveFailures = 0
            phase = Policies.badgeCount(result) > 0 ? .updatesAvailable : .upToDate
        } catch let error as BrewCheckError {
            fail(with: error.userMessage)
        } catch {
            fail(with: error.localizedDescription)
        }
    }

    private func fail(with message: String) {
        consecutiveFailures += 1
        lastErrorMessage = message
        phase = .failed
    }
}