import SwiftUI

struct BackgroundView: View {
    @ObservedObject var configManager = ConfigManager.shared

    private func spacer(_ geometry: GeometryProxy) -> some View {
        let theme: ColorScheme? = {
            switch configManager.config.rootToml.theme {
            case "dark": return .dark
            case "light": return .light
            default: return nil
            }
        }()

        let height = configManager.config.experimental.background.resolveHeight()

        return Color.clear
            .frame(height: height ?? geometry.size.height)
            .preferredColorScheme(theme)

    }

    var body: some View {
        if configManager.config.experimental.background.displayed {
            // When glass style is active, the background panel must be transparent
            // so .glassEffect() on the menuBarPanel can sample the real desktop.
            // Glass can't sample other glass/blur.
            if configManager.config.appearance.renderingStyle == .glass {
                Color.clear
            } else {
                GeometryReader { geometry in
                    if configManager.config.experimental.background.black {
                        spacer(geometry)
                            .background(.black)
                            .id("black")
                    } else {
                        spacer(geometry)
                            .background(configManager.config.experimental.background.blur)
                            .id("blur")
                    }
                }
            }
        }
    }
}
