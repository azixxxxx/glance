import SwiftUI

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case widgets = "Widgets"
    case spaces = "Spaces"
    case time = "Time"
    case about = "About"

    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .widgets: return "square.grid.2x2"
        case .spaces: return "rectangle.3.group"
        case .time: return "clock"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            switch selectedTab {
            case .general:
                GeneralSettingsTab()
            case .widgets:
                WidgetsSettingsTab()
            case .spaces:
                SpacesSettingsTab()
            case .time:
                TimeSettingsTab()
            case .about:
                AboutSettingsTab()
            }
        }
    }
}
