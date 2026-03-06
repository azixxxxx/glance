import SwiftUI

struct SpacesSettingsTab: View {
    @ObservedObject var configManager = ConfigManager.shared

    @State private var showKey: Bool = true
    @State private var showTitle: Bool = true
    @State private var maxLength: Double = 50

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsSection(title: "Space Indicators") {
                    Toggle("Show space number / key", isOn: $showKey)
                        .onChange(of: showKey) { _, newValue in
                            configManager.updateConfigValue(
                                key: "widgets.default.spaces.space.show-key",
                                newValue: newValue ? "true" : "false")
                        }
                }

                SettingsSection(title: "Window Titles") {
                    Toggle("Show focused window title", isOn: $showTitle)
                        .onChange(of: showTitle) { _, newValue in
                            configManager.updateConfigValue(
                                key: "widgets.default.spaces.window.show-title",
                                newValue: newValue ? "true" : "false")
                        }
                    SliderRow(label: "Max title length", value: $maxLength, range: 10...100, step: 5, format: "%.0f") {
                        configManager.updateConfigValue(
                            key: "widgets.default.spaces.window.title.max-length",
                            newValue: String(Int(maxLength)))
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .onAppear { syncFromConfig() }
    }

    private func syncFromConfig() {
        let spacesConfig = configManager.globalWidgetConfig(for: "default.spaces")
        let spaceSection = spacesConfig["space"]?.dictionaryValue ?? [:]
        let windowSection = spacesConfig["window"]?.dictionaryValue ?? [:]
        let titleSection = windowSection["title"]?.dictionaryValue ?? [:]

        showKey = spaceSection["show-key"]?.boolValue ?? true
        showTitle = windowSection["show-title"]?.boolValue ?? true
        maxLength = Double(titleSection["max-length"]?.intValue ?? 50)
    }
}
