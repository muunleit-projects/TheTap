import AppKit
import Foundation
import os

/// Fires the automatic check triggers: startup, a repeating timer and wake from
/// sleep. Every trigger only calls `AppState.checkIfDue()`, which decides
/// whether a check really runs.
@MainActor
final class Scheduler {
    private let state: AppState
    private let logger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "scheduler")

    private var startupTask: Task<Void, Never>?
    private var wakeTask: Task<Void, Never>?
    private var wakeObserver: NSObjectProtocol?
    private var activity: NSBackgroundActivityScheduler?

    private static let startupDelay: Duration = .seconds(10)
    private static let wakeDelay: Duration = .seconds(60)
    /// The timer ticks at one third of the check interval, but at most this often.
    private static let maxTick: TimeInterval = 15 * 60

    init(state: AppState) {
        self.state = state
    }

    func start() {
        startupTask = Task { [weak self] in
            try? await Task.sleep(for: Self.startupDelay)
            guard !Task.isCancelled else { return }
            await self?.trigger("startup")
        }
        observeWake()
        restartActivity()
    }

    /// (Re)creates the repeating timer from the current check interval.
    /// Phase 6 calls this when the user changes the interval.
    func restartActivity() {
        activity?.invalidate()
        let tick = min(state.checkInterval / 3, Self.maxTick)
        let scheduler = NSBackgroundActivityScheduler(
            identifier: "io.github.muunleit-projects.thetap.check")
        scheduler.repeats = true
        scheduler.interval = tick
        scheduler.tolerance = tick / 4
        scheduler.qualityOfService = .utility
        scheduler.schedule { @Sendable [weak self] completion in
            Task { @MainActor in await self?.trigger("timer") }
            completion(.finished)
        }
        activity = scheduler
        logger.notice("Timer set: tick every \(tick, privacy: .public) s")
    }

    private func observeWake() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.scheduleWakeCheck() }
        }
    }

    private func scheduleWakeCheck() {
        logger.notice("Mac woke up, check in \(Self.wakeDelay.components.seconds, privacy: .public) s")
        wakeTask?.cancel()
        wakeTask = Task { [weak self] in
            try? await Task.sleep(for: Self.wakeDelay)
            guard !Task.isCancelled else { return }
            await self?.trigger("wake")
        }
    }

    private func trigger(_ reason: String) async {
        logger.notice("Trigger: \(reason, privacy: .public)")
        await state.checkIfDue()
    }
}