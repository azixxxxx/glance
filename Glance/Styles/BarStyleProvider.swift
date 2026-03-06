import SwiftUI

// MARK: - Style Enum

enum BarStyle: String, CaseIterable {
    case glass
    case solid
    case minimal
}

// MARK: - Environment Keys

private struct BarStyleKey: EnvironmentKey {
    static let defaultValue: BarStyle = .glass
}

private struct AppearanceConfigKey: EnvironmentKey {
    static let defaultValue: AppearanceConfig = Preset.liquidGlass.defaults
}

extension EnvironmentValues {
    var barStyle: BarStyle {
        get { self[BarStyleKey.self] }
        set { self[BarStyleKey.self] = newValue }
    }

    var appearance: AppearanceConfig {
        get { self[AppearanceConfigKey.self] }
        set { self[AppearanceConfigKey.self] = newValue }
    }
}

// MARK: - Persistent Blur (always-active NSVisualEffectView)

/// NSVisualEffectView wrapper with `.state = .active` so blur renders
/// regardless of whether the hosting window is key/active.
struct PersistentBlurView: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

// MARK: - Widget Style Modifier

/// Applied to individual widget capsules.
/// Uses AppearanceConfig for all visual parameters including colors.
struct WidgetStyleModifier: ViewModifier {
    let appearance: AppearanceConfig
    let heightOverride: CGFloat?

    private var cornerRadius: CGFloat {
        appearance.resolvedWidgetCornerRadius(height: heightOverride ?? 38)
    }

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        switch appearance.renderingStyle {
        case .glass:
            content
                .background(
                    ZStack {
                        PersistentBlurView(material: appearance.blurMaterial)
                        appearance.widgetBackgroundColor.opacity(appearance.fillOpacity)
                    }
                )
                .clipShape(shape)
                .overlay(
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    appearance.borderColor.opacity(appearance.borderTopOpacity),
                                    appearance.borderColor.opacity(appearance.borderMidOpacity),
                                    appearance.borderColor.opacity(appearance.borderBottomOpacity),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: appearance.borderWidth
                        )
                )
                .shadow(color: appearance.glowColor.opacity(appearance.glowOpacity), radius: appearance.glowRadius)
                .shadow(color: .black.opacity(appearance.shadowOpacity), radius: appearance.shadowRadius, y: appearance.shadowY)
        case .solid:
            content
                .background(appearance.widgetBackgroundColor.opacity(appearance.fillOpacity))
                .clipShape(shape)
                .overlay(
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: appearance.borderColor2 != nil
                                    ? [
                                        appearance.borderColor.opacity(appearance.borderTopOpacity),
                                        appearance.borderColor2!.opacity(appearance.borderTopOpacity),
                                    ]
                                    : [
                                        appearance.borderColor.opacity(appearance.borderTopOpacity),
                                        appearance.borderColor.opacity(appearance.borderMidOpacity),
                                        appearance.borderColor.opacity(appearance.borderBottomOpacity),
                                    ],
                                startPoint: appearance.borderColor2 != nil ? .leading : .top,
                                endPoint: appearance.borderColor2 != nil ? .trailing : .bottom
                            ),
                            lineWidth: appearance.borderWidth
                        )
                )
                .shadow(color: appearance.glowColor.opacity(appearance.glowOpacity), radius: appearance.glowRadius)
                .shadow(color: appearance.borderColor2 != nil
                    ? appearance.borderColor2!.opacity(appearance.glowOpacity * 0.5)
                    : .clear,
                    radius: appearance.glowRadius)
                .shadow(color: .black.opacity(appearance.shadowOpacity), radius: appearance.shadowRadius, y: appearance.shadowY)
        case .minimal:
            content
        }
    }
}

// MARK: - Popup Style Modifier

/// Applied to popup panels (calendar, volume, network, etc.)
struct PopupStyleModifier: ViewModifier {
    let appearance: AppearanceConfig
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        switch appearance.renderingStyle {
        case .glass:
            if #available(macOS 26, *) {
                content
                    .glassEffect(.regular, in: shape)
            } else {
                content
                    .background(
                        ZStack {
                            PersistentBlurView(material: appearance.blurMaterial)
                            appearance.widgetBackgroundColor.opacity(appearance.fillOpacity)
                            Color.black.opacity(appearance.popupDarkTint)
                        }
                    )
                    .clipShape(shape)
                    .overlay(
                        shape
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        appearance.borderColor.opacity(min(appearance.borderTopOpacity * 1.4, 1.0)),
                                        appearance.borderColor.opacity(min(appearance.borderMidOpacity * 1.4, 1.0)),
                                        appearance.borderColor.opacity(min(appearance.borderBottomOpacity * 1.5, 1.0)),
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: max(appearance.borderWidth, 1.0)
                            )
                    )
                    .shadow(color: appearance.glowColor.opacity(appearance.glowOpacity * 1.6), radius: appearance.glowRadius + 1)
                    .shadow(color: .black.opacity(0.20), radius: 16, y: 6)
            }
        case .solid:
            content
                .background(
                    shape.fill(appearance.widgetBackgroundColor)
                )
                .clipShape(shape)
                .overlay(
                    shape
                        .strokeBorder(
                            appearance.borderColor.opacity(0.3),
                            lineWidth: 0.5
                        )
                )
        case .minimal:
            content
                .background(
                    shape.fill(Color.black.opacity(appearance.popupDarkTint > 0 ? appearance.popupDarkTint : 0.70))
                )
                .clipShape(shape)
        }
    }
}

// MARK: - View Extensions

extension View {
    func widgetStyle(_ appearance: AppearanceConfig, heightOverride: CGFloat? = nil) -> some View {
        modifier(WidgetStyleModifier(appearance: appearance, heightOverride: heightOverride))
    }

    func popupStyle(_ appearance: AppearanceConfig, cornerRadius: CGFloat) -> some View {
        modifier(PopupStyleModifier(appearance: appearance, cornerRadius: cornerRadius))
    }
}
