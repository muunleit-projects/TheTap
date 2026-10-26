import SwiftUI
import UserNotifications

/// The settings window (`Settings` scene).
struct SettingsView: View {
    let state: AppState

    @AppStorage(AppState.checkIntervalKey) private var checkInterval = AppState.defaultCheckInterval
    @AppStorage(Notifier.enabledKey) private var notificationsEnabled = true
    @AppStorage(AppState.includeGreedyKey) private var includeGreedy = true
    @State private var systemAllowsNotifications = true

    private static let intervals: [(label: String, seconds: Double)] = [
        ("Jede Stunde", 3600),
        ("Alle 3 Stunden", 10800),
        ("Alle 6 Stunden (Standard)", 21600),
        ("Alle 12 Stunden", 43200),
        ("Einmal täglich", 86400),
    ]

    var body: some View {
        Form {
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
        .onAppear { NSApp.activate() }
        .task { await refreshNotificationStatus() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await refreshNotificationStatus() }
        }
        .onChange(of: checkInterval) {
            state.checkIntervalChanged()
        }
    }

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