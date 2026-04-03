import SwiftUI
import UniformTypeIdentifiers

struct GeneralSettingsTab: View {
    @ObservedObject var configManager = ConfigManager.shared
    @ObservedObject var customPresets = CustomPresetStore.shared

    @State private var selectedPreset: String = "liquid-glass"
    @State private var showPresetEditor: Bool = false
    @State private var editingPresetName: String?
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
    @State private var selectedFormation: String = "islands"
    @State private var formationMargin: Double = 8
    @State private var formationGap: Double = 10
    @State private var neonColor: Color = Color(red: 1, green: 0.27, blue: 0.8)
    @State private var neonColor2: Color = Color(red: 0.27, green: 0.8, blue: 1)
    @State private var useGradient: Bool = false
    @State private var hotkeyString: String = "ctrl+option+b"
    @State private var hotkeyValid: Bool = true
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
                        if !customPresets.presetNames.isEmpty {
                            Divider()
                            ForEach(customPresets.presetNames, id: \.self) { name in
                                Text(name).tag("custom:\(name)")
                            }
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedPreset) { _, newValue in
                        guard !isSyncing else { return }
                        if newValue.hasPrefix("custom:") {
                            applyCustomPreset(name: String(newValue.dropFirst(7)))
                        } else if let preset = Preset(rawValue: newValue) {
                            applyBuiltinPreset(preset)
                        }
                    }

                    HStack(spacing: 8) {
                        Button("Create Preset...") {
                            editingPresetName = nil
                            showPresetEditor = true
                        }
                        if selectedPreset.hasPrefix("custom:") {
                            Button("Edit...") {
                                editingPresetName = String(selectedPreset.dropFirst(7))
                                showPresetEditor = true
                            }
                            Button("Delete") {
                                let name = String(selectedPreset.dropFirst(7))
                                customPresets.delete(name: name)
                                selectedPreset = "liquid-glass"
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .sheet(isPresented: $showPresetEditor, onDismiss: {
                        // If a new preset was created/edited, select it
                        if let name = editingPresetName ?? customPresets.presetNames.last {
                            if customPresets.presetNames.contains(name) {
                                selectedPreset = "custom:\(name)"
                            }
                        }
                    }) {
                        PresetEditorView(
                            store: customPresets,
                            editingName: editingPresetName
                        )
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

                // MARK: - Formation
                SettingsSection(title: "Formation") {
                    FormationPicker(selected: $selectedFormation)
                        .onChange(of: selectedFormation) { _, newValue in
                            guard !isSyncing else { return }
                            configManager.updateConfigValue(
                                key: "experimental.foreground.formation",
                                newValue: newValue)
                        }

                    if selectedFormation == "floating" || selectedFormation == "pills" {
                        SliderRow(label: "Margin", value: $formationMargin, range: 0...40, step: 1, format: "%.0f px") {
                            configManager.updateConfigValue(
                                key: "experimental.foreground.margin",
                                newValue: String(Int(formationMargin)))
                        }
                    }
                    if selectedFormation == "pills" {
                        SliderRow(label: "Gap", value: $formationGap, range: 4...30, step: 1, format: "%.0f px") {
                            configManager.updateConfigValue(
                                key: "experimental.foreground.gap",
                                newValue: String(Int(formationGap)))
                        }
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

                // MARK: - Hotkey
                SettingsSection(title: "Global Hotkey") {
                    HStack {
                        Text("Toggle bar")
                            .frame(width: 130, alignment: .leading)
                        TextField("ctrl+option+b", text: $hotkeyString)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 200)
                            .onChange(of: hotkeyString) { _, newValue in
                                guard !isSyncing else { return }
                                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                                if trimmed == "false" || HotkeyManager.parse(trimmed) != nil {
                                    hotkeyValid = true
                                    configManager.updateConfigValue(key: "hotkey", newValue: trimmed)
                                } else {
                                    hotkeyValid = false
                                }
                            }
                        if !hotkeyValid {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    Text("Format: modifier+modifier+key (e.g. ctrl+option+b, cmd+shift+space). Set to \"false\" to disable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Share Preset
                SettingsSection(title: "Share Preset") {
                    HStack(spacing: 12) {
                        Button("Export Preset...") { PresetShareManager.exportPreset() }
                        Button("Import Preset...") { PresetShareManager.importPreset() }
                        Button("Copy Share Link") { PresetShareManager.copyShareLink() }
                    }
                    Text("Share your visual preset as a .glance file or a glance:// link. Others can open it to apply your style.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Config
                SettingsSection(title: "Configuration") {
                    HStack(spacing: 12) {
                        Button("Export Config...") { exportConfig() }
                        Button("Import Config...") { importConfig() }
                    }
                    Text("Export saves your full config to a file. Import replaces it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(24)
        }
        .onAppear { syncFromConfig() }
    }

    // MARK: - Export / Import

    private func exportConfig() {
        guard let sourcePath = configManager.configFilePath else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "glance-config.toml"
        panel.allowedContentTypes = [.init(filenameExtension: "toml") ?? .plainText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let dest = panel.url else { return }
        try? FileManager.default.copyItem(at: URL(fileURLWithPath: sourcePath), to: dest)
    }

    private func importConfig() {
        guard let destPath = configManager.configFilePath else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "toml") ?? .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let source = panel.url else { return }
        try? FileManager.default.removeItem(atPath: destPath)
        try? FileManager.default.copyItem(at: source, to: URL(fileURLWithPath: destPath))
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
        selectedFormation = exp.foreground.formation.rawValue
        formationMargin = exp.foreground.margin
        formationGap = exp.foreground.gap
        hotkeyString = root.hotkey ?? "ctrl+option+b"
        hotkeyValid = true
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

    // MARK: - Preset apply/save helpers

    private func applyBuiltinPreset(_ preset: Preset) {
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

        var pairs: [(key: String, value: String)] = [
            ("preset", preset.rawValue),
            ("appearance.roundness", String(Int(d.roundness))),
            ("appearance.border-width", String(format: "%.1f", d.borderWidth)),
            ("appearance.border-opacity", String(format: "%.2f", d.borderTopOpacity)),
            ("appearance.fill-opacity", String(format: "%.2f", d.fillOpacity)),
            ("appearance.glow-opacity", String(format: "%.2f", d.glowOpacity)),
            ("appearance.shadow-opacity", String(format: "%.2f", d.shadowOpacity)),
            ("appearance.shadow-radius", String(format: "%.0f", d.shadowRadius)),
        ]
        if preset.rawValue != "neon" {
            pairs.append(("appearance.neon-color", ""))
            pairs.append(("appearance.neon-color2", ""))
        }
        configManager.updateConfigValues(pairs: pairs)
    }

    private func applyCustomPreset(name: String) {
        guard let values = customPresets.load(name: name) else { return }
        isSyncing = true
        if let v = values["roundness"], let d = Double(v) { roundness = d }
        if let v = values["border-width"], let d = Double(v) { borderWidth = d }
        if let v = values["border-top-opacity"], let d = Double(v) { borderOpacity = d }
        if let v = values["fill-opacity"], let d = Double(v) { fillOpacity = d }
        if let v = values["glow-opacity"], let d = Double(v) { glowOpacity = d }
        if let v = values["shadow-opacity"], let d = Double(v) { shadowOpacity = d }
        if let v = values["shadow-radius"], let d = Double(v) { shadowRadius = d }
        isSyncing = false

        // Determine the rendering style to pick the right base preset
        let style = values["rendering-style"] ?? "glass"
        let basePreset: String
        switch style {
        case "solid": basePreset = "flat-dark"
        case "minimal": basePreset = "minimal"
        default: basePreset = "liquid-glass"
        }

        var pairs: [(key: String, value: String)] = [
            ("preset", basePreset),
            ("appearance.roundness", String(Int(roundness))),
            ("appearance.border-width", String(format: "%.1f", borderWidth)),
            ("appearance.border-opacity", String(format: "%.2f", borderOpacity)),
            ("appearance.fill-opacity", String(format: "%.2f", fillOpacity)),
            ("appearance.glow-opacity", String(format: "%.2f", glowOpacity)),
            ("appearance.shadow-opacity", String(format: "%.2f", shadowOpacity)),
            ("appearance.shadow-radius", String(format: "%.0f", shadowRadius)),
        ]
        // Apply custom colors via neon-color overrides (accent/border/glow)
        if let ac = values["accent-color"] { pairs.append(("appearance.neon-color", ac)) }
        if let bc2 = values["border-color2"] { pairs.append(("appearance.neon-color2", bc2)) }
        configManager.updateConfigValues(pairs: pairs)
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

// MARK: - Formation Picker

private struct FormationPicker: View {
    @Binding var selected: String

    private let formations: [(id: String, label: String)] = [
        ("full", "Full"),
        ("floating", "Floating"),
        ("islands", "Islands"),
        ("pills", "Pills"),
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(formations, id: \.id) { f in
                FormationCard(
                    id: f.id,
                    label: f.label,
                    isSelected: selected == f.id
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selected = f.id
                    }
                }
            }
        }
    }
}

private struct FormationCard: View {
    let id: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                FormationDiagram(formation: id)
                    .frame(height: 32)

                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Formation Diagrams (Schematic Drawings)

private struct FormationDiagram: View {
    let formation: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            switch formation {
            case "full":
                fullDiagram(w: w, h: h)
            case "floating":
                floatingDiagram(w: w, h: h)
            case "islands":
                islandsDiagram(w: w, h: h)
            case "pills":
                pillsDiagram(w: w, h: h)
            default:
                EmptyView()
            }
        }
    }

    // Full: flat edge-to-edge bar like macOS menubar (no rounding)
    @ViewBuilder
    private func fullDiagram(w: CGFloat, h: CGFloat) -> some View {
        let barH: CGFloat = 10

        screenOutline(w: w, h: h)

        // Flat bar — no corner radius, touching screen edges
        Rectangle()
            .fill(Color.white.opacity(0.35))
            .frame(width: w - 2, height: barH)
            .position(x: w / 2, y: barH / 2 + 1)

        widgetDots(count: 6, in: CGRect(x: 4, y: 1, width: w - 8, height: barH))
    }

    // Floating: continuous bar with margins
    @ViewBuilder
    private func floatingDiagram(w: CGFloat, h: CGFloat) -> some View {
        let barH: CGFloat = 10
        let margin: CGFloat = 10
        let y = (h - barH) / 2

        screenOutline(w: w, h: h)

        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.35))
            .frame(width: w - 8 - margin * 2, height: barH)
            .position(x: w / 2, y: y + barH / 2 + 2)

        widgetDots(count: 5, in: CGRect(x: 6 + margin, y: y + 2, width: w - 12 - margin * 2, height: barH))
    }

    // Islands: separate capsules
    @ViewBuilder
    private func islandsDiagram(w: CGFloat, h: CGFloat) -> some View {
        let barH: CGFloat = 10
        let y = (h - barH) / 2 + 2
        let gap: CGFloat = 4
        let capsuleWidths: [CGFloat] = [0.25, 0.12, 0.18, 0.1, 0.15]
        let totalRatio = capsuleWidths.reduce(0, +)
        let usableW = w - 8 - gap * CGFloat(capsuleWidths.count - 1)

        screenOutline(w: w, h: h)

        HStack(spacing: gap) {
            ForEach(0..<capsuleWidths.count, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: usableW * capsuleWidths[i] / totalRatio, height: barH)
            }
        }
        .position(x: w / 2, y: y + barH / 2)
    }

    // Pills: 2-3 grouped segments separated by space
    @ViewBuilder
    private func pillsDiagram(w: CGFloat, h: CGFloat) -> some View {
        let barH: CGFloat = 10
        let y = (h - barH) / 2 + 2
        let groupGap: CGFloat = 8
        let usableW = w - 8 - groupGap * 2

        screenOutline(w: w, h: h)

        HStack(spacing: groupGap) {
            // Left pill (wider)
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.35))
                smallDots(count: 3)
            }
            .frame(width: usableW * 0.38, height: barH)

            Spacer(minLength: 0)

            // Center pill
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.35))
                smallDots(count: 2)
            }
            .frame(width: usableW * 0.25, height: barH)

            Spacer(minLength: 0)

            // Right pill
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.35))
                smallDots(count: 3)
            }
            .frame(width: usableW * 0.30, height: barH)
        }
        .padding(.horizontal, 4)
        .position(x: w / 2, y: y + barH / 2)
    }

    // MARK: - Shared drawing helpers

    @ViewBuilder
    private func screenOutline(w: CGFloat, h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            .frame(width: w - 2, height: h - 2)
            .position(x: w / 2, y: h / 2)
    }

    @ViewBuilder
    private func widgetDots(count: Int, in rect: CGRect) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 4, height: 4)
            }
        }
        .position(x: rect.midX, y: rect.midY)
    }

    @ViewBuilder
    private func smallDots(count: Int) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 3, height: 3)
            }
        }
    }
}
