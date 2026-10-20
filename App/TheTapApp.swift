import SwiftUI

@main
struct TheTapApp: App {
    @State private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            PanelView(state: state)
        } label: {
            MenuBarLabel(state: state)
        }
        .menuBarExtraStyle(.window)
    }
}