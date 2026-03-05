import SwiftUI

// MARK: - Style Enum

enum BarStyle: String, CaseIterable {
    case glass
    case solid
    case minimal
    case system
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
/// Uses AppearanceConfig for all visual parameters.
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
                        Color.white.opacity(appearance.fillOpacity)
                    }
                )
                .clipShape(shape)
                .overlay(
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(appearance.borderTopOpacity),
                                    .white.opacity(appearance.borderMidOpacity),
                                    .white.opacity(appearance.borderBottomOpacity),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: appearance.borderWidth
                        )
                )
                .shadow(color: .white.opacity(appearance.glowOpacity), radius: appearance.glowRadius)
                .shadow(color: .black.opacity(appearance.shadowOpacity), radius: appearance.shadowRadius, y: appearance.shadowY)
        case .solid:
            content
                .background(Color.white.opacity(appearance.fillOpacity))
                .clipShape(shape)
                .overlay(
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(appearance.borderTopOpacity),
                                    .white.opacity(appearance.borderMidOpacity),
                                    .white.opacity(appearance.borderBottomOpacity),
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: appearance.borderWidth
                        )
                )
                .shadow(color: .white.opacity(appearance.glowOpacity), radius: appearance.glowRadius)
                .shadow(color: .black.opacity(appearance.shadowOpacity), radius: appearance.shadowRadius, y: appearance.shadowY)
        case .minimal:
            content
        case .system:
            content
                .background(.regularMaterial)
                .clipShape(shape)
        }
    }
}

// MARK: - Popup Style Modifier

/// Applied to popup panels (calendar, volume, network, etc.)
/// Popups use native .glassEffect() since the popup panel IS key when visible.
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
                            Color.white.opacity(appearance.fillOpacity)
                            Color.black.opacity(appearance.popupDarkTint)
                        }
                    )
                    .clipShape(shape)
                    .overlay(
                        shape
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(min(appearance.borderTopOpacity * 1.4, 1.0)),
                                        .white.opacity(min(appearance.borderMidOpacity * 1.4, 1.0)),
                                        .white.opacity(min(appearance.borderBottomOpacity * 1.5, 1.0)),
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: max(appearance.borderWidth, 1.0)
                            )
                    )
                    .shadow(color: .white.opacity(appearance.glowOpacity * 1.6), radius: appearance.glowRadius + 1)
                    .shadow(color: .black.opacity(0.20), radius: 16, y: 6)
            }
        case .solid:
            content
                .background(
                    shape.fill(Color(white: 0.12))
                )
                .clipShape(shape)
        case .minimal:
            content
                .background(
                    shape.fill(Color.black.opacity(appearance.popupDarkTint > 0 ? appearance.popupDarkTint : 0.70))
                )
                .clipShape(shape)
        case .system:
            content
                .background(.regularMaterial)
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
