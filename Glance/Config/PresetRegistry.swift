import AppKit

/// Built-in visual presets. Each preset defines all appearance parameters.
enum Preset: String, CaseIterable {
    case liquidGlass = "liquid-glass"
    case frosted = "frosted"
    case flatDark = "flat-dark"
    case minimalStrip = "minimal-strip"
    case systemNative = "system-native"
    case neon = "neon"

    /// Full appearance defaults for this preset.
    var defaults: AppearanceConfig {
        switch self {
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
                popupRoundness: 40
            )
        case .frosted:
            return AppearanceConfig(
                renderingStyle: .glass,
                roundness: 12,
                borderWidth: 0.5,
                borderTopOpacity: 0.20,
                borderMidOpacity: 0.10,
                borderBottomOpacity: 0.05,
                fillOpacity: 0.06,
                glowOpacity: 0.02,
                glowRadius: 1,
                shadowOpacity: 0.06,
                shadowRadius: 3,
                shadowY: 2,
                blurMaterial: .popover,
                popupDarkTint: 0.30,
                popupRoundness: 16
            )
        case .flatDark:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 8,
                borderWidth: 0.5,
                borderTopOpacity: 0.10,
                borderMidOpacity: 0.10,
                borderBottomOpacity: 0.10,
                fillOpacity: 0.08,
                glowOpacity: 0,
                glowRadius: 0,
                shadowOpacity: 0,
                shadowRadius: 0,
                shadowY: 0,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 12
            )
        case .minimalStrip:
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
                popupRoundness: 12
            )
        case .systemNative:
            return AppearanceConfig(
                renderingStyle: .system,
                roundness: 10,
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
                popupDarkTint: 0,
                popupRoundness: 12
            )
        case .neon:
            return AppearanceConfig(
                renderingStyle: .solid,
                roundness: 20,
                borderWidth: 1.5,
                borderTopOpacity: 0.70,
                borderMidOpacity: 0.40,
                borderBottomOpacity: 0.20,
                fillOpacity: 0.06,
                glowOpacity: 0.15,
                glowRadius: 4,
                shadowOpacity: 0.12,
                shadowRadius: 8,
                shadowY: 3,
                blurMaterial: .popover,
                popupDarkTint: 0,
                popupRoundness: 24
            )
        }
    }

    /// Maps legacy `style = "..."` values to a preset.
    static func fromLegacyStyle(_ style: String) -> Preset {
        switch style {
        case "glass": return .liquidGlass
        case "solid": return .flatDark
        case "minimal": return .minimalStrip
        case "system": return .systemNative
        default: return .liquidGlass
        }
    }
}
