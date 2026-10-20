import SwiftUI

@main
struct TheTapApp: App {
    var body: some Scene {
        MenuBarExtra("TheTap", systemImage: "mug") {
            VStack(alignment: .leading, spacing: 8) {
                Text("TheTap läuft")
                Button("Beenden") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding()
        }
        .menuBarExtraStyle(.window)
    }
}