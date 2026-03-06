import SwiftUI

/// All visual parameters for widget/popup rendering.
/// Resolved from a preset + optional user overrides.
struct AppearanceConfig {
    let renderingStyle: BarStyle
    let roundness: CGFloat          // 0 = square, 50 = capsule
    let borderWidth: CGFloat
    let borderTopOpacity: CGFloat
    let borderMidOpacity: CGFloat
    let borderBottomOpacity: CGFloat
    let fillOpacity: CGFloat
    let glowOpacity: CGFloat
    let glowRadius: CGFloat
    let shadowOpacity: CGFloat
    let shadowRadius: CGFloat
    let shadowY: CGFloat
    let blurMaterial: NSVisualEffectView.Material
    let popupDarkTint: CGFloat
    let popupRoundness: CGFloat

    // Colors
    let foregroundColor: Color
    let accentColor: Color
    let borderColor: Color
    let borderColor2: Color?        // Non-nil = gradient border
    let widgetBackgroundColor: Color
    let glowColor: Color

    /// Maps roundness (0-50) to a concrete cornerRadius for widget capsules.
    func resolvedWidgetCornerRadius(height: CGFloat = 38) -> CGFloat {
        let clamped = min(max(roundness, 0), 50)
        let maxRadius = height / 2
        return maxRadius * (clamped / 50)
    }

    /// Maps popupRoundness to a concrete cornerRadius for popups.
    func resolvedPopupCornerRadius() -> CGFloat {
        popupRoundness
    }

    /// Creates a copy with user overrides applied.
    func applying(overrides: AppearanceOverrides?) -> AppearanceConfig {
        guard let o = overrides else { return self }

        // Parse neon custom colors
        let customColor1 = o.neonColor.flatMap { Self.parseHex($0) }
        let customColor2 = o.neonColor2.flatMap { Self.parseHex($0) }

        return AppearanceConfig(
            renderingStyle: renderingStyle,
            roundness: o.roundness ?? roundness,
            borderWidth: o.borderWidth ?? borderWidth,
            borderTopOpacity: o.borderOpacity ?? borderTopOpacity,
            borderMidOpacity: o.borderOpacity.map { $0 * 0.375 } ?? borderMidOpacity,
            borderBottomOpacity: o.borderOpacity.map { $0 * 0.2 } ?? borderBottomOpacity,
            fillOpacity: o.fillOpacity ?? fillOpacity,
            glowOpacity: o.glowOpacity ?? glowOpacity,
            glowRadius: glowRadius,
            shadowOpacity: o.shadowOpacity ?? shadowOpacity,
            shadowRadius: o.shadowRadius ?? shadowRadius,
            shadowY: shadowY,
            blurMaterial: blurMaterial,
            popupDarkTint: popupDarkTint,
            popupRoundness: popupRoundness,
            foregroundColor: foregroundColor,
            accentColor: customColor1 ?? accentColor,
            borderColor: customColor1 ?? borderColor,
            borderColor2: customColor2 ?? borderColor2,
            widgetBackgroundColor: widgetBackgroundColor,
            glowColor: customColor1 ?? glowColor
        )
    }

    // MARK: - Hex parsing

    static func parseHex(_ hex: String) -> Color? {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard h.count == 6 else { return nil }
        let scanner = Scanner(string: h)
        var rgb: UInt64 = 0
        guard scanner.scanHexInt64(&rgb) else { return nil }
        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

/// Decodable user overrides from `[appearance]` in TOML.
/// All fields optional — only specified values override the preset.
struct AppearanceOverrides: Decodable {
    let roundness: CGFloat?
    let borderWidth: CGFloat?
    let borderOpacity: CGFloat?
    let fillOpacity: CGFloat?
    let glowOpacity: CGFloat?
    let shadowOpacity: CGFloat?
    let shadowRadius: CGFloat?
    let neonColor: String?
    let neonColor2: String?

    enum CodingKeys: String, CodingKey {
        case roundness
        case borderWidth = "border-width"
        case borderOpacity = "border-opacity"
        case fillOpacity = "fill-opacity"
        case glowOpacity = "glow-opacity"
        case shadowOpacity = "shadow-opacity"
        case shadowRadius = "shadow-radius"
        case neonColor = "neon-color"
        case neonColor2 = "neon-color2"
    }
}
