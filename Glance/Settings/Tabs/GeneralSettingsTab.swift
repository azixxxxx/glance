import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var configManager = ConfigManager.shared

    @State private var selectedPreset: String = "liquid-glass"
    @State private var roundness: Double = 50
    @State private var borderWidth: Double = 1.0
    @State private var borderOpacity: Double = 0.4
    @State private var fillOpacity: Double = 0.04
    @State private var glowOpacity: Double = 0.05
    @State private var shadowOpacity: Double = 0.08
    @State private var shadowRadius: Double = 4.0
    @State private var barHeight: Double = 55
    @State private var horizontalPadding: Double = 25
    @State private var widgetSpacing: Double = 15
    @State private var showWidgetBackgrounds: Bool = false
    @State private var blurWallpaper: Bool = true
    @State private var neonColor: Color = Color(red: 1, green: 0.27, blue: 0.8)
    @State private var neonColor2: Color = Color(red: 0.27, green: 0.8, blue: 1)
    @State private var useGradient: Bool = false
    @State private var isSyncing: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Preset
                SettingsSection(title: "Preset") {
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(Preset.allCases, id: \.rawValue) { preset in
                            Text(presetDisplayName(preset)).tag(preset.rawValue)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedPreset) { _, newValue in
                        guard !isSyncing else { return }
                        if let preset = Preset(rawValue: newValue) {
                            let d = preset.defaults
                            isSyncing = true
                            withAnimation(.easeInOut(duration: 0.2)) {
                                roundness = d.roundness
                                borderWidth = d.borderWidth
                                borderOpacity = d.borderTopOpacity
                                fillOpacity = d.fillOpacity
                                glowOpacity = d.glowOpacity
                                shadowOpacity = d.shadowOpacity
                                shadowRadius = d.shadowRadius
                            }
                            isSyncing = false

                            // Write preset + clear all appearance overrides in one file write
                            var pairs: [(key: String, value: String)] = [
                                ("preset", newValue),
                                ("appearance.roundness", String(Int(d.roundness))),
                                ("appearance.border-width", String(format: "%.1f", d.borderWidth)),
                                ("appearance.border-opacity", String(format: "%.2f", d.borderTopOpacity)),
                                ("appearance.fill-opacity", String(format: "%.2f", d.fillOpacity)),
                                ("appearance.glow-opacity", String(format: "%.2f", d.glowOpacity)),
                                ("appearance.shadow-opacity", String(format: "%.2f", d.shadowOpacity)),
                                ("appearance.shadow-radius", String(format: "%.0f", d.shadowRadius)),
                            ]
                            // Clear neon colors when switching away from neon
                            if newValue != "neon" {
                                pairs.append(("appearance.neon-color", ""))
                                pairs.append(("appearance.neon-color2", ""))
                            }
                            configManager.updateConfigValues(pairs: pairs)
                        }
                    }
                }

                // MARK: - Neon Colors (only when Neon preset)
                if selectedPreset == "neon" {
                    SettingsSection(title: "Neon Colors") {
                        HStack {
                            Text("Accent Color")
                                .frame(width: 130, alignment: .leading)
                            ColorPicker("", selection: $neonColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: neonColor) { _, newValue in
                                    guard !isSyncing else { return }
                                    configManager.updateConfigValue(
                                        key: "appearance.neon-color",
                                        newValue: newValue.toHex())
                                }
                        }
                        Toggle("Gradient Border", isOn: $useGradient)
                            .onChange(of: useGradient) { _, newValue in
                                guard !isSyncing else { return }
                                if newValue {
                                    configManager.updateConfigValue(
                                        key: "appearance.neon-color2",
                                        newValue: neonColor2.toHex())
                                } else {
                                    configManager.updateConfigValue(
                                        key: "appearance.neon-color2",
                                        newValue: "")
                                }
                            }
                        if useGradient {
                            HStack {
                                Text("Second Color")
                                    .frame(width: 130, alignment: .leading)
                                ColorPicker("", selection: $neonColor2, supportsOpacity: false)
                                    .labelsHidden()
                                    .onChange(of: neonColor2) { _, newValue in
                                        guard !isSyncing else { return }
                                        configManager.updateConfigValue(
                                            key: "appearance.neon-color2",
                                            newValue: newValue.toHex())
                                    }
                            }
                        }
                    }
                }

                // MARK: - Appearance Overrides
                SettingsSection(title: "Appearance") {
                    SliderRow(label: "Roundness", value: $roundness, range: 0...50, step: 1, format: "%.0f") {
                        configManager.updateConfigValue(key: "appearance.roundness", newValue: String(Int(roundness)))
                    }
                    SliderRow(label: "Border Width", value: $borderWidth, range: 0...3, step: 0.1, format: "%.1f") {
                        configManager.updateConfigValue(key: "appearance.border-width", newValue: String(format: "%.1f", borderWidth))
                    }
                    SliderRow(label: "Border Opacity", value: $borderOpacity, range: 0...1, step: 0.01, format: "%.2f") {
                        configManager.updateConfigValue(key: "appearance.border-opacity", newValue: String(format: "%.2f", borderOpacity))
                    }
                    SliderRow(label: "Fill Opacity", value: $fillOpacity, range: 0...1, step: 0.01, format: "%.2f") {
                        configManager.updateConfigValue(key: "appearance.fill-opacity", newValue: String(format: "%.2f", fillOpacity))
                    }
                    SliderRow(label: "Glow Opacity", value: $glowOpacity, range: 0...0.5, step: 0.01, format: "%.2f") {
                        configManager.updateConfigValue(key: "appearance.glow-opacity", newValue: String(format: "%.2f", glowOpacity))
                    }
                    SliderRow(label: "Shadow Opacity", value: $shadowOpacity, range: 0...0.5, step: 0.01, format: "%.2f") {
                        configManager.updateConfigValue(key: "appearance.shadow-opacity", newValue: String(format: "%.2f", shadowOpacity))
                    }
                    SliderRow(label: "Shadow Radius", value: $shadowRadius, range: 0...20, step: 1, format: "%.0f") {
                        configManager.updateConfigValue(key: "appearance.shadow-radius", newValue: String(format: "%.0f", shadowRadius))
                    }
                }

                // MARK: - Bar Layout
                SettingsSection(title: "Bar Layout") {
                    Toggle("Blur Wallpaper", isOn: $blurWallpaper)
                        .onChange(of: blurWallpaper) { _, newValue in
                            guard !isSyncing else { return }
                            configManager.updateConfigValue(key: "experimental.background.displayed", newValue: newValue ? "true" : "false")
                        }
                    SliderRow(label: "Bar Height", value: $barHeight, range: 25...80, step: 1, format: "%.0f px") {
                        configManager.updateConfigValue(key: "experimental.foreground.height", newValue: String(Int(barHeight)))
                    }
                    SliderRow(label: "Horizontal Padding", value: $horizontalPadding, range: 0...60, step: 1, format: "%.0f px") {
                        configManager.updateConfigValue(key: "experimental.foreground.horizontal-padding", newValue: String(Int(horizontalPadding)))
                    }
                    SliderRow(label: "Widget Spacing", value: $widgetSpacing, range: 4...30, step: 1, format: "%.0f px") {
                        configManager.updateConfigValue(key: "experimental.foreground.spacing", newValue: String(Int(widgetSpacing)))
                    }
                    Toggle("Show Widget Backgrounds", isOn: $showWidgetBackgrounds)
                        .onChange(of: showWidgetBackgrounds) { _, newValue in
                            guard !isSyncing else { return }
                            configManager.updateConfigValue(key: "experimental.foreground.widgets-background.displayed", newValue: newValue ? "true" : "false")
                        }
                }

                Spacer()
            }
            .padding(24)
        }
        .onAppear { syncFromConfig() }
    }

    private func syncFromConfig() {
        isSyncing = true
        defer { isSyncing = false }

        let config = configManager.config
        let root = config.rootToml

        if let presetName = root.preset {
            selectedPreset = presetName
        } else if let style = root.style {
            selectedPreset = Preset.fromLegacyStyle(style).rawValue
        } else {
            selectedPreset = "liquid-glass"
        }

        let a = config.appearance
        roundness = a.roundness
        borderWidth = a.borderWidth
        borderOpacity = a.borderTopOpacity
        fillOpacity = a.fillOpacity
        glowOpacity = a.glowOpacity
        shadowOpacity = a.shadowOpacity
        shadowRadius = a.shadowRadius

        let exp = config.experimental
        barHeight = exp.foreground.resolveHeight()
        horizontalPadding = exp.foreground.horizontalPadding
        widgetSpacing = exp.foreground.spacing
        showWidgetBackgrounds = exp.foreground.widgetsBackground.displayed
        blurWallpaper = exp.background.displayed
        syncNeonColors()
    }

    private func syncNeonColors() {
        let overrides = configManager.config.rootToml.appearanceOverrides
        if let hex = overrides?.neonColor, let c = AppearanceConfig.parseHex(hex) {
            neonColor = c
        }
        if let hex2 = overrides?.neonColor2, !hex2.isEmpty, let c = AppearanceConfig.parseHex(hex2) {
            neonColor2 = c
            useGradient = true
        } else {
            useGradient = false
        }
    }

    private func presetDisplayName(_ preset: Preset) -> String {
        switch preset {
        case .liquidGlass: return "Liquid Glass"
        case .frosted:     return "Frosted"
        case .flatDark:    return "Flat Dark"
        case .minimal:     return "Minimal"
        case .neon:        return "Neon"
        case .tokyoNight:  return "Tokyo Night"
        case .dracula:     return "Dracula"
        case .gruvbox:     return "Gruvbox"
        case .nord:        return "Nord"
        case .catppuccin:  return "Catppuccin"
        case .solarized:   return "Solarized"
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    func toHex() -> String {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return "#ff44cc" }
        let r = Int(round(components.redComponent * 255))
        let g = Int(round(components.greenComponent * 255))
        let b = Int(round(components.blueComponent * 255))
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}

// MARK: - Reusable Components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(16)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var format: String = "%.0f"
    var onCommit: () -> Void = {}

    @State private var isEditing = false

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 130, alignment: .leading)
            Slider(value: $value, in: range, step: step, onEditingChanged: { editing in
                isEditing = editing
                if !editing {
                    onCommit()
                }
            })
            Text(String(format: format, value))
                .monospacedDigit()
                .frame(width: 55, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}
