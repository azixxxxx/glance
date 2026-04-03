import AppKit
import Foundation

enum PresetShareManager {

    // MARK: - Export

    /// Export current appearance config as a .glance file via NSSavePanel.
    static func exportPreset() {
        let config = ConfigManager.shared.config
        let root = config.rootToml

        var lines: [String] = ["# Glance Preset"]

        if let preset = root.preset {
            lines.append("preset = \"\(preset)\"")
        }

        let formation = config.experimental.foreground.formation
        lines.append("formation = \"\(formation.rawValue)\"")

        if let overrides = root.appearanceOverrides {
            lines.append("")
            lines.append("[appearance]")
            if let v = overrides.roundness { lines.append("roundness = \(Int(v))") }
            if let v = overrides.borderWidth { lines.append("border-width = \(String(format: "%.1f", v))") }
            if let v = overrides.borderOpacity { lines.append("border-opacity = \(String(format: "%.2f", v))") }
            if let v = overrides.fillOpacity { lines.append("fill-opacity = \(String(format: "%.2f", v))") }
            if let v = overrides.glowOpacity { lines.append("glow-opacity = \(String(format: "%.2f", v))") }
            if let v = overrides.shadowOpacity { lines.append("shadow-opacity = \(String(format: "%.2f", v))") }
            if let v = overrides.shadowRadius { lines.append("shadow-radius = \(String(format: "%.0f", v))") }
            if let v = overrides.neonColor { lines.append("neon-color = \"\(v)\"") }
            if let v = overrides.neonColor2 { lines.append("neon-color2 = \"\(v)\"") }
        }

        let content = lines.joined(separator: "\n") + "\n"

        let panel = NSSavePanel()
        panel.nameFieldStringValue = "my-preset.glance"
        panel.allowedContentTypes = [.init(filenameExtension: "glance") ?? .plainText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let dest = panel.url else { return }
        try? content.write(to: dest, atomically: true, encoding: .utf8)
    }

    /// Export current preset as a shareable URL (glance://preset/<base64>).
    static func copyShareLink() {
        let config = ConfigManager.shared.config
        let root = config.rootToml

        var lines: [String] = []
        if let preset = root.preset { lines.append("preset = \"\(preset)\"") }
        let formation = config.experimental.foreground.formation
        lines.append("formation = \"\(formation.rawValue)\"")

        if let o = root.appearanceOverrides {
            lines.append("[appearance]")
            if let v = o.roundness { lines.append("roundness = \(Int(v))") }
            if let v = o.borderWidth { lines.append("border-width = \(String(format: "%.1f", v))") }
            if let v = o.borderOpacity { lines.append("border-opacity = \(String(format: "%.2f", v))") }
            if let v = o.fillOpacity { lines.append("fill-opacity = \(String(format: "%.2f", v))") }
            if let v = o.glowOpacity { lines.append("glow-opacity = \(String(format: "%.2f", v))") }
            if let v = o.shadowOpacity { lines.append("shadow-opacity = \(String(format: "%.2f", v))") }
            if let v = o.shadowRadius { lines.append("shadow-radius = \(String(format: "%.0f", v))") }
            if let v = o.neonColor { lines.append("neon-color = \"\(v)\"") }
            if let v = o.neonColor2 { lines.append("neon-color2 = \"\(v)\"") }
        }

        let content = lines.joined(separator: "\n")
        guard let data = content.data(using: .utf8) else { return }
        let encoded = data.base64EncodedString()
        let urlString = "glance://preset/\(encoded)"

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(urlString, forType: .string)
    }

    // MARK: - Import

    /// Import a .glance preset file via NSOpenPanel.
    static func importPreset() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "glance") ?? .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        applyPresetFile(at: url)
    }

    /// Apply a .glance preset file to the current config.
    static func applyPresetFile(at url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        applyPresetContent(content)
    }

    /// Apply a glance:// URL by decoding its base64 payload.
    static func applyPresetURL(_ url: URL) {
        // glance://preset/<base64>
        guard url.scheme == "glance", url.host == "preset" else { return }
        let encoded = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let data = Data(base64Encoded: encoded),
              let content = String(data: data, encoding: .utf8)
        else { return }
        applyPresetContent(content)
    }

    // MARK: - Private

    private static func applyPresetContent(_ content: String) {
        var pairs: [(key: String, value: String)] = []

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), !trimmed.hasPrefix("[") else { continue }

            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            switch key {
            case "preset":
                pairs.append(("preset", value))
            case "formation":
                pairs.append(("experimental.foreground.formation", value))
            case "roundness":
                pairs.append(("appearance.roundness", value))
            case "border-width":
                pairs.append(("appearance.border-width", value))
            case "border-opacity":
                pairs.append(("appearance.border-opacity", value))
            case "fill-opacity":
                pairs.append(("appearance.fill-opacity", value))
            case "glow-opacity":
                pairs.append(("appearance.glow-opacity", value))
            case "shadow-opacity":
                pairs.append(("appearance.shadow-opacity", value))
            case "shadow-radius":
                pairs.append(("appearance.shadow-radius", value))
            case "neon-color":
                pairs.append(("appearance.neon-color", value))
            case "neon-color2":
                pairs.append(("appearance.neon-color2", value))
            default:
                break
            }
        }

        guard !pairs.isEmpty else { return }
        ConfigManager.shared.updateConfigValues(pairs: pairs)
    }
}
