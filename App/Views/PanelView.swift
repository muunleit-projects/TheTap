import SwiftUI

/// The panel that opens when the menu bar icon is clicked.
struct PanelView: View {
    let state: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if !state.packages.isEmpty {
                PackageListView(packages: state.packages)
            }
            Divider()
            HStack {
                Button("Jetzt prüfen") {
                    Task { await state.checkNow() }
                }
                .disabled(state.isChecking)
                Spacer()
                Button("Beenden") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 340)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.statusText)
                .font(.headline)
            if let lastSuccess = state.lastSuccess {
                // Re-evaluated every minute so "vor 12 Min." stays current.
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text("Zuletzt geprüft: \(Self.relativeText(for: lastSuccess, now: context.date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private static func relativeText(for date: Date, now: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: now)
    }
}