import SwiftUI

struct WallpaperSettingsTab: View {
    @ObservedObject private var themeManager = WallpaperThemeManager.shared
    @State private var showPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Adaptive Colors
                SettingsSection(title: "Adaptive Colors") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Match bar colors to wallpaper")
                            Text("Automatically extracts dominant colors from the current desktop wallpaper and applies them to the bar.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { themeManager.isEnabled },
                            set: { enabled in
                                if enabled { themeManager.enable() }
                                else { themeManager.disable() }
                            }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }

                    if themeManager.isEnabled {
                        Divider()
                        // Color preview
                        if let palette = themeManager.currentPalette {
                            PalettePreview(palette: palette)
                        } else {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Extracting colors...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("Refresh from Current Wallpaper") {
                            themeManager.refreshFromCurrentWallpaper()
                        }
                        .controlSize(.small)
                    }
                }

                // MARK: - Wallpaper Picker
                SettingsSection(title: "Wallpaper Picker") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Browse and pick wallpapers")
                            Text("Opens a visual picker showing your wallpapers with live color previews of how the bar will look.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Open Picker...") {
                            showPicker = true
                        }
                        .sheet(isPresented: $showPicker) {
                            WallpaperPickerView()
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
        }
    }
}

// MARK: - Palette preview component

private struct PalettePreview: View {
    let palette: WallpaperPalette

    var body: some View {
        HStack(spacing: 16) {
            // Swatch row
            HStack(spacing: 6) {
                ForEach(Array(palette.allColors.prefix(6).enumerated()), id: \.offset) { _, color in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(color))
                        .frame(width: 24, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }

            Divider().frame(height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Background")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(palette.dominantBackground))
                        .frame(width: 14, height: 14)
                    Text(palette.dominantBackground.hexString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Accent")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(palette.primaryAccent))
                        .frame(width: 14, height: 14)
                    Text(palette.primaryAccent.hexString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - NSColor hex helper

extension NSColor {
    var hexString: String {
        guard let srgb = usingColorSpace(.sRGB) else { return "#??????" }
        let r = Int(round(srgb.redComponent * 255))
        let g = Int(round(srgb.greenComponent * 255))
        let b = Int(round(srgb.blueComponent * 255))
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}
