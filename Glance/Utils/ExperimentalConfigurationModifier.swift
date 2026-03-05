import SwiftUI

private struct ExperimentalConfigurationModifier: ViewModifier {
    @ObservedObject var configManager = ConfigManager.shared
    @Environment(\.appearance) private var appearance

    var foregroundHeight: CGFloat {
        configManager.config.experimental.foreground.resolveHeight()
    }

    let horizontalPadding: CGFloat

    func body(content: Content) -> some View {
        Group {
            if !configManager.config.experimental.foreground.widgetsBackground
                .displayed
            {
                content
            } else {
                content
                    .frame(height: foregroundHeight < 45 ? 30 : 38)
                    .padding(
                        .horizontal,
                        foregroundHeight < 45 && horizontalPadding != 15
                            ? 0
                            : foregroundHeight < 30
                                ? 0 : horizontalPadding
                    )
                    .widgetStyle(
                        appearance,
                        heightOverride: foregroundHeight < 45 ? 30 : 38
                    )
            }
        }.scaleEffect(foregroundHeight < 25 ? 0.9 : 1, anchor: .leading)
    }
}

extension View {
    func experimentalConfiguration(
        horizontalPadding: CGFloat = 15
    ) -> some View {
        self.modifier(
            ExperimentalConfigurationModifier(
                horizontalPadding: horizontalPadding
            ))
    }
}
