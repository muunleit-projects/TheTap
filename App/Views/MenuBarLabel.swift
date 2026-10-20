import SwiftUI

/// Icon (and number of updates) shown in the menu bar.
struct MenuBarLabel: View {
    let state: AppState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
            if state.phase == .updatesAvailable {
                Text("\(state.badgeCount)")
            }
        }
    }

    private var iconName: String {
        switch state.phase {
        case .checking:
            return "arrow.triangle.2.circlepath"
        case .updatesAvailable:
            return "mug.fill"
        case .failed:
            return "exclamationmark.triangle"
        case .notChecked, .upToDate, .offline:
            return "mug"
        }
    }
}