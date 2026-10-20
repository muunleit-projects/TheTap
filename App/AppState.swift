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
    private(set) var isOnline = true

    private let checker = BrewChecker()
    private var upgradeTimeout: Task<Void, Never>?

    /// If no recheck arrives (Terminal window closed early), the upgrade state ends after this.
    private static let upgradeTimeoutDuration: Duration = .seconds(2 * 60 * 60)

    /// Check interval until the settings exist (Phase 6).
    private static let defaultCheckInterval: TimeInterval = 6 * 60 * 60

    /// Number shown next to the menu bar icon (pinned packages do not count).
    var badgeCount: Int { Policies.badgeCount(packages) }

    var isChecking: Bool { phase == .checking }

    /// Whether "Alles aktualisieren" can be used right now.
    var canUpgrade: Bool { badgeCount > 0 && !upgradeRunning && !isChecking }

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

    /// Runs `brew outdated`, preceded by `brew update` unless `runUpdate` is false.
    /// Ignored while a check is running. Offline, it only sets the offline phase.
    func checkNow(runUpdate: Bool = true) async {
        guard phase != .checking else { return }
        guard isOnline else {
            phase = .offline
            return
        }
        phase = .checking
        lastErrorMessage = nil
        do {
            let result = try await checker.outdated(runUpdate: runUpdate)
            packages = result
            lastSuccess = Date()
            consecutiveFailures = 0
            phase = Policies.badgeCount(result) > 0 ? .updatesAvailable : .upToDate
        } catch let error as BrewCheckError {
            failCheck(with: error.userMessage)
        } catch {
            failCheck(with: error.localizedDescription)
        }
    }

    /// Called by the network monitor whenever reachability changes.
    func networkChanged(isOnline online: Bool) {
        guard online != isOnline else { return }
        isOnline = online
        if !online {
            // A running check ends by itself and then lands in the offline phase.
            if phase != .checking { phase = .offline }
            return
        }
        guard phase == .offline else { return }
        if Policies.isCheckDue(
            lastSuccess: lastSuccess, interval: Self.defaultCheckInterval, now: Date())
        {
            Task { await checkNow() }
        } else {
            restorePhase()
        }
    }

    /// Opens Terminal with the upgrade script and enters the "upgrade running" state.
    func startUpgrade(greedy: Bool = true) {
        guard canUpgrade else { return }
        do {
            try UpgradeLauncher.start(greedy: greedy)
            upgradeRunning = true
            scheduleUpgradeTimeout()
        } catch let error as BrewCheckError {
            fail(with: error.userMessage)
        } catch let error as UpgradeLaunchError {
            fail(with: error.userMessage)
        } catch {
            fail(with: error.localizedDescription)
        }
    }

    /// Ends the "upgrade running" state without checking.
    func finishUpgrade() {
        upgradeTimeout?.cancel()
        upgradeTimeout = nil
        upgradeRunning = false
    }

    /// Called when Terminal reports the upgrade is done (`thetap://recheck`).
    /// Brew data is fresh then, so `brew update` is skipped.
    func recheckAfterUpgrade() async {
        finishUpgrade()
        await checkNow(runUpdate: false)
    }

    private func scheduleUpgradeTimeout() {
        upgradeTimeout?.cancel()
        upgradeTimeout = Task { [weak self] in
            try? await Task.sleep(for: Self.upgradeTimeoutDuration)
            guard !Task.isCancelled else { return }
            self?.finishUpgrade()
        }
    }

    /// A failed check while the network is gone is "offline", not an error.
    private func failCheck(with message: String) {
        if isOnline {
            fail(with: message)
        } else {
            phase = .offline
        }
    }

    private func fail(with message: String) {
        consecutiveFailures += 1
        lastErrorMessage = message
        phase = .failed
    }

    /// Goes back to the phase that matches the last known result.
    private func restorePhase() {
        if badgeCount > 0 {
            phase = .updatesAvailable
        } else if lastSuccess != nil {
            phase = .upToDate
        } else {
            phase = .notChecked
        }
    }
}