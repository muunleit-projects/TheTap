import ServiceManagement
import SwiftUI
import UserNotifications
import os

/// The settings window (`Settings` scene).
struct SettingsView: View {
    let state: AppState

    @AppStorage(AppState.checkIntervalKey) private var checkInterval = AppState.defaultCheckInterval
    @AppStorage(Notifier.enabledKey) private var notificationsEnabled = true
    @AppStorage(AppState.includeGreedyKey) private var includeGreedy = true
    @State private var systemAllowsNotifications = true
    @State private var loginStatus = SMAppService.mainApp.status
    @State private var loginError: String?

    private let logger = Logger(
        subsystem: "io.github.muunleit-projects.thetap", category: "settings")

    private static let intervals: [(label: String, seconds: Double)] = [
        ("Jede Stunde", 3600),
        ("Alle 3 Stunden", 10800),
        ("Alle 6 Stunden (Standard)", 21600),
        ("Alle 12 Stunden", 43200),
        ("Einmal täglich", 86400),
    ]

    /// The switch is on while the login item is registered, even if the user
    /// still has to approve it in the system settings.
    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { loginStatus == .enabled || loginStatus == .requiresApproval },
            set: { setLaunchAtLogin($0) }
        )
    }

    var body: some View {
        Form {
            Section("Start") {
                Toggle("Beim Anmelden starten", isOn: launchAtLoginBinding)
                if loginStatus == .requiresApproval {
                    Text("macOS wartet auf deine Freigabe in den Systemeinstellungen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Anmeldeobjekte öffnen") {
                        SMAppService.openSystemSettingsLoginItems()
                    }
                }
                if loginStatus == .notFound {
                    Text("macOS findet die App nicht als Anmeldeobjekt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let loginError {
                    Text(loginError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section("Prüfung") {
                Picker("Prüfintervall", selection: $checkInterval) {
                    ForEach(Self.intervals, id: \.seconds) { interval in
                        Text(interval.label).tag(interval.seconds)
                    }
                }
                Toggle("Casks mit eigenem Updater einbeziehen", isOn: $includeGreedy)
                Text("Gilt für die Prüfung und für „Alles aktualisieren“ (brew --greedy).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Mitteilungen") {
                Toggle("Mitteilungen senden", isOn: $notificationsEnabled)
                if !systemAllowsNotifications {
                    Text("In den Systemeinstellungen sind Mitteilungen für TheTap nicht erlaubt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Systemeinstellungen öffnen") {
                        openNotificationSettings()
                    }
                }
            }
            Section("Log") {
                Button("Log im Finder zeigen") {
                    revealLog()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            NSApp.activate()
            refreshLoginStatus()
        }
        .task { await refreshNotificationStatus() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshLoginStatus()
            Task { await refreshNotificationStatus() }
        }
        .onChange(of: checkInterval) {
            state.checkIntervalChanged()
        }
    }

    // MARK: Launch at login

    /// Reads the status again, because the user can also change it in the system settings.
    private func refreshLoginStatus() {
        loginStatus = SMAppService.mainApp.status
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        loginError = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            logger.notice(
                "Launch at login \(enabled ? "registered" : "unregistered", privacy: .public)")
        } catch {
            logger.error(
                "Launch at login failed: \(error.localizedDescription, privacy: .public)")
            loginError = enabled
                ? "Anmelden-Start konnte nicht eingeschaltet werden: \(error.localizedDescription)"
                : "Anmelden-Start konnte nicht ausgeschaltet werden: \(error.localizedDescription)"
        }
        refreshLoginStatus()
        logger.notice("Login item status: \(String(describing: loginStatus), privacy: .public)")
    }

    // MARK: Notifications

    private func refreshNotificationStatus() async {
        systemAllowsNotifications = await state.notifier.isAllowedBySystem()
    }

    private func openNotificationSettings() {
        let specific = URL(
            string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")!
        if !NSWorkspace.shared.open(specific) {
            _ = NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
        }
    }

    // MARK: Log

    /// Shows the log file in Finder; if it does not exist yet, opens its folder instead.
    private func revealLog() {
        let url = state.logFile.url
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            let folder = url.deletingLastPathComponent()
            if fileManager.fileExists(atPath: folder.path) {
                NSWorkspace.shared.open(folder)
            }
        }
    }
}