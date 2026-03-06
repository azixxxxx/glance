import SwiftUI

struct WidgetsSettingsTab: View {
    @ObservedObject var configManager = ConfigManager.shared
    @State private var activeWidgets: [String] = []

    private let allAvailableWidgets: [(id: String, label: String, icon: String)] = [
        ("default.spaces", "Spaces", "rectangle.3.group"),
        ("default.activeapp", "Active App", "app.badge.fill"),
        ("default.nowplaying", "Now Playing", "music.note"),
        ("default.volume", "Volume", "speaker.wave.2"),
        ("default.network", "Network", "wifi"),
        ("default.battery", "Battery", "battery.75percent"),
        ("default.time", "Time", "clock"),
        ("spacer", "Spacer", "arrow.left.and.right"),
        ("divider", "Divider", "minus"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsSection(title: "Active Widgets") {
                    Text("Drag to reorder. Click \u{2212} to remove.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(Array(activeWidgets.enumerated()), id: \.offset) { index, widgetId in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.tertiary)

                            Image(systemName: iconFor(widgetId))
                                .frame(width: 20)

                            Text(labelFor(widgetId))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: {
                                removeWidget(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)

                            // Move up/down
                            Button(action: { moveWidget(at: index, direction: -1) }) {
                                Image(systemName: "chevron.up")
                            }
                            .buttonStyle(.plain)
                            .disabled(index == 0)

                            Button(action: { moveWidget(at: index, direction: 1) }) {
                                Image(systemName: "chevron.down")
                            }
                            .buttonStyle(.plain)
                            .disabled(index == activeWidgets.count - 1)
                        }
                        .padding(.vertical, 4)
                    }
                }

                SettingsSection(title: "Add Widget") {
                    let inactive = allAvailableWidgets.filter { widget in
                        // spacer and divider can be added multiple times
                        if widget.id == "spacer" || widget.id == "divider" { return true }
                        return !activeWidgets.contains(widget.id)
                    }

                    if inactive.isEmpty {
                        Text("All widgets are active")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(inactive, id: \.id) { widget in
                            HStack {
                                Image(systemName: widget.icon)
                                    .frame(width: 20)
                                Text(widget.label)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button(action: {
                                    addWidget(widget.id)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
        .onAppear { syncFromConfig() }
    }

    private func syncFromConfig() {
        activeWidgets = configManager.config.rootToml.widgets.displayed.map { $0.id }
    }

    private func labelFor(_ id: String) -> String {
        allAvailableWidgets.first(where: { $0.id == id })?.label ?? id
    }

    private func iconFor(_ id: String) -> String {
        allAvailableWidgets.first(where: { $0.id == id })?.icon ?? "questionmark"
    }

    private func removeWidget(at index: Int) {
        activeWidgets.remove(at: index)
        writeWidgetList()
    }

    private func addWidget(_ id: String) {
        activeWidgets.append(id)
        writeWidgetList()
    }

    private func moveWidget(at index: Int, direction: Int) {
        let newIndex = index + direction
        guard newIndex >= 0, newIndex < activeWidgets.count else { return }
        activeWidgets.swapAt(index, newIndex)
        writeWidgetList()
    }

    private func writeWidgetList() {
        let listString = activeWidgets
            .map { "\"\($0)\"" }
            .joined(separator: ", ")
        configManager.updateConfigValue(
            key: "widgets.displayed",
            newValue: "[\(listString)]")
    }
}
