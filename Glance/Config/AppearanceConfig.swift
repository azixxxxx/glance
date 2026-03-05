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

    /// Maps roundness (0-50) to a concrete cornerRadius for widget capsules.
    /// 50 = height/2 = full capsule shape.
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
            popupRoundness: popupRoundness
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

    enum CodingKeys: String, CodingKey {
        case roundness
        case borderWidth = "border-width"
        case borderOpacity = "border-opacity"
        case fillOpacity = "fill-opacity"
        case glowOpacity = "glow-opacity"
        case shadowOpacity = "shadow-opacity"
        case shadowRadius = "shadow-radius"
    }
}
