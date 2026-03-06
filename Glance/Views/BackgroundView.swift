import SwiftUI

struct BackgroundView: View {
    @ObservedObject var configManager = ConfigManager.shared

    var body: some View {
        let bg = configManager.config.experimental.background
        GeometryReader { geometry in
            let height = bg.resolveHeight()
            if bg.black {
                Color.clear
                    .frame(height: height ?? geometry.size.height)
                    .background(.black)
            } else {
                Color.clear
                    .frame(height: height ?? geometry.size.height)
                    .background(bg.blur)
            }
        }
        .opacity(bg.displayed ? 1 : 0)
        .preferredColorScheme(.dark)
    }
}
