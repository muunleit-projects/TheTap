import BrewCheck
import Foundation
import Observation
import os

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
    private let logger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "scheduler")
    private var upgradeTimeout: Task<Void, Never>?
    private var recheckPending = false

    /// If no recheck arrives (Terminal window closed early), the upgrade state ends after this.
    private static let upgradeTimeoutDuration: Duration = .seconds(2 * 60 * 60)

    /// `UserDefaults` key for the check interval in seconds (the settings window writes it in Phase 6).
    static let checkIntervalKey = "checkInterval"

    /// Default check interval: 6 hours.
    static let defaultCheckInterval: TimeInterval = 21600

    /// Check interval in seconds. Read on every access, so a changed value applies at once.
    var checkInterval: TimeInterval {
        let value = UserDefaults.standard.double(forKey: Self.checkIntervalKey)
        return value > 0 ? value : Self.defaultCheckInterval
    }

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

    /// Entry point for all automatic triggers. Starts a check with `brew update`
    /// only if no check is running, no upgrade is running, the network is up and
    /// a check is due. Every decision is logged.
    func checkIfDue() async {
        guard phase != .checking else {
            logger.notice("Skipped: a check is already running")
            return
        }
        guard !upgradeRunning else {
            logger.notice("Skipped: an upgrade is running")
            return
        }
        guard isOnline else {
            logger.notice("Skipped: offline")
            phase = .offline
            return
        }
        let interval = checkInterval
        guard Policies.isCheckDue(lastSuccess: lastSuccess, interval: interval, now: Date()) else {
            logger.notice("Skipped: not due yet (interval \(interval, privacy: .public) s)")
            return
        }
        logger.notice("Starting check")
        await checkNow()
    }

    /// Runs `brew outdated`, preceded by `brew update` unless `runUpdate` is false.
    /// Ignored while a check is running. A recheck that arrived meanwhile runs
    /// right afterwards, without `brew update`.
    func checkNow(runUpdate: Bool = true) async {
        await performCheck(runUpdate: runUpdate)
        while recheckPending {
            recheckPending = false
            logger.notice("Running queued recheck")
            await performCheck(runUpdate: false)
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
        Task {
            await checkIfDue()
            // Nothing was due: go back to the phase of the last known result.
            if isOnline, phase == .offline { restorePhase() }
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
    /// Brew data is fresh then, so `brew update` is skipped. If a check is
    /// running right now, the recheck is queued and runs right after it.
    func recheckAfterUpgrade() async {
        finishUpgrade()
        if isChecking {
            logger.notice("Recheck queued: a check is running")
            recheckPending = true
            return
        }
        await checkNow(runUpdate: false)
    }

    private func performCheck(runUpdate: Bool) async {
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