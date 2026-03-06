import AppKit
import SwiftUI

/// Built-in visual presets. Each preset is a complete visual identity —
/// rendering style, colors, and shape parameters.
enum Preset: String, CaseIterable {
    case liquidGlass  = "liquid-glass"
    case frosted      = "frosted"
    case flatDark     = "flat-dark"
    case minimal      = "minimal"
    case neon         = "neon"
    case tokyoNight   = "tokyo-night"
    case dracula      = "dracula"
    case gruvbox      = "gruvbox"
    case nord         = "nord"
    case catppuccin   = "catppuccin"
    case solarized    = "solarized"

    // MARK: - Hex helper

    private static func hex(_ hex: String) -> Color {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    /// Full appearance defaults for this preset.
    var defaults: AppearanceConfig {
        switch self {

        // ── Glass presets ─────────────────────────────────────────

        case .liquidGlass:
            return AppearanceConfig(
                renderingStyle: .glass,
                roundness: 50,
                borderWidth: 1.0,
                borderTopOpacity: 0.40,
                borderMidOpacity: 0.15,
                borderBottomOpacity: 0.08,
                fillOpacity: 0.04,
                glowOpacity: 0.05,
                glowRadius: 2,
                shadowOpacity: 0.08,
                shadowRadius: 4,
                shadowY: 2,
                blurMaterial: .popover,
                popupDarkTint: 0.25,
                popupRoundness: 40,
                foregroundColor: .white,
                accentColor: .white,
                borderColor: .white,
                borderColor2: nil,
                widgetBackgroundColor: .white,
                glowColor: .white
            )

        case .frosted:
            return AppearanceConfig(
                renderingStyle: .glass,
                roundness: 12,
                borderWidth: 0.5,
                borderTopOpacity: 0.15,
                borderMidOpacity: 0.08,
                borderBottomOpacity: 0.04,
                fillOpacity: 0.20,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0.04,
                shadowRadius: 2,
                shadowY: 1,
                blurMaterial: .hudWindow,
                popupDarkTint: 0.40,
                popupRoundness: 16,
                foregroundColor: .white,
                accentColor: .white.opacity(0.9),
                borderColor: .white,
                borderColor2: nil,
                widgetBackgroundColor: .white,
                glowColor: .clear
            )

        // ── Flat presets ──────────────────────────────────────────

        case .flatDark:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 8,
                borderWidth: 0.5,
                borderTopOpacity: 0.12,
                borderMidOpacity: 0.12,
                borderBottomOpacity: 0.12,
                fillOpacity: 0.85,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0,
                shadowRadius: 0,
                shadowY: 0,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 12,
                foregroundColor: Self.hex("#e0e0e0"),
                accentColor: .white,
                borderColor: Self.hex("#333333"),
                borderColor2: nil,
                widgetBackgroundColor: Self.hex("#1c1c1c"),
                glowColor: .clear
            )

        case .minimal:
            return AppearanceConfig(
                renderingStyle: .minimal,
                roundness: 0,
                borderWidth: 0,
                borderTopOpacity: 0,
                borderMidOpacity: 0,
                borderBottomOpacity: 0,
                fillOpacity: 0,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0,
                shadowRadius: 0,
                shadowY: 0,
                blurMaterial: .popover,
                popupDarkTint: 0.70,
                popupRoundness: 12,
                foregroundColor: .white,
                accentColor: .white,
                borderColor: .clear,
                borderColor2: nil,
                widgetBackgroundColor: .clear,
                glowColor: .clear
            )

        case .neon:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 20,
                borderWidth: 1.5,
                borderTopOpacity: 0.80,
                borderMidOpacity: 0.50,
                borderBottomOpacity: 0.30,
                fillOpacity: 0.90,
                glowOpacity: 0.30,
                glowRadius: 6,
                shadowOpacity: 0.20,
                shadowRadius: 10,
                shadowY: 0,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 24,
                foregroundColor: Self.hex("#f0f0f0"),
                accentColor: Self.hex("#ff44cc"),
                borderColor: Self.hex("#ff44cc"),
                borderColor2: nil,
                widgetBackgroundColor: Self.hex("#0a0a0a"),
                glowColor: Self.hex("#ff44cc")
            )

        // ── Color scheme presets ──────────────────────────────────

        case .tokyoNight:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 8,
                borderWidth: 0.5,
                borderTopOpacity: 0.20,
                borderMidOpacity: 0.20,
                borderBottomOpacity: 0.20,
                fillOpacity: 0.90,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0.05,
                shadowRadius: 3,
                shadowY: 2,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 12,
                foregroundColor: Self.hex("#a9b1d6"),
                accentColor: Self.hex("#7aa2f7"),
                borderColor: Self.hex("#414868"),
                borderColor2: nil,
                widgetBackgroundColor: Self.hex("#1a1b26"),
                glowColor: .clear
            )

        case .dracula:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 8,
                borderWidth: 0.5,
                borderTopOpacity: 0.20,
                borderMidOpacity: 0.20,
                borderBottomOpacity: 0.20,
                fillOpacity: 0.90,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0.05,
                shadowRadius: 3,
                shadowY: 2,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 12,
                foregroundColor: Self.hex("#f8f8f2"),
                accentColor: Self.hex("#bd93f9"),
                borderColor: Self.hex("#6272a4"),
                borderColor2: nil,
                widgetBackgroundColor: Self.hex("#282a36"),
                glowColor: .clear
            )

        case .gruvbox:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 8,
                borderWidth: 0.5,
                borderTopOpacity: 0.20,
                borderMidOpacity: 0.20,
                borderBottomOpacity: 0.20,
                fillOpacity: 0.90,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0.05,
                shadowRadius: 3,
                shadowY: 2,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 12,
                foregroundColor: Self.hex("#ebdbb2"),
                accentColor: Self.hex("#fe8019"),
                borderColor: Self.hex("#504945"),
                borderColor2: nil,
                widgetBackgroundColor: Self.hex("#282828"),
                glowColor: .clear
            )

        case .nord:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 8,
                borderWidth: 0.5,
                borderTopOpacity: 0.20,
                borderMidOpacity: 0.20,
                borderBottomOpacity: 0.20,
                fillOpacity: 0.90,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0.05,
                shadowRadius: 3,
                shadowY: 2,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 12,
                foregroundColor: Self.hex("#d8dee9"),
                accentColor: Self.hex("#88c0d0"),
                borderColor: Self.hex("#3b4252"),
                borderColor2: nil,
                widgetBackgroundColor: Self.hex("#2e3440"),
                glowColor: .clear
            )

        case .catppuccin:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 10,
                borderWidth: 0.5,
                borderTopOpacity: 0.20,
                borderMidOpacity: 0.20,
                borderBottomOpacity: 0.20,
                fillOpacity: 0.90,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0.05,
                shadowRadius: 3,
                shadowY: 2,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 12,
                foregroundColor: Self.hex("#cdd6f4"),
                accentColor: Self.hex("#cba6f7"),
                borderColor: Self.hex("#45475a"),
                borderColor2: nil,
                widgetBackgroundColor: Self.hex("#1e1e2e"),
                glowColor: .clear
            )

        case .solarized:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 8,
                borderWidth: 0.5,
                borderTopOpacity: 0.20,
                borderMidOpacity: 0.20,
                borderBottomOpacity: 0.20,
                fillOpacity: 0.90,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0.05,
                shadowRadius: 3,
                shadowY: 2,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 12,
                foregroundColor: Self.hex("#839496"),
                accentColor: Self.hex("#268bd2"),
                borderColor: Self.hex("#073642"),
                borderColor2: nil,
                widgetBackgroundColor: Self.hex("#002b36"),
                glowColor: .clear
            )
        }
    }

    /// Maps legacy `style = "..."` values to a preset.
    static func fromLegacyStyle(_ style: String) -> Preset {
        switch style {
        case "glass": return .liquidGlass
        case "solid": return .flatDark
        case "minimal": return .minimal
        default: return .liquidGlass
        }
    }
}
