import SwiftUI

struct OnboardingView: View {
    let onDismiss: () -> Void

    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        (
            "sparkles",
            "Welcome to Glance",
            "A modern status bar for macOS with liquid glass UI, live widgets, and full customization."
        ),
        (
            "square.grid.2x2",
            "Rich Widgets",
            "Spaces, Now Playing, Battery, Volume, Network, Time & Calendar — all at a glance."
        ),
        (
            "paintpalette",
            "Visual Presets",
            "Choose from Liquid Glass, Frosted, Tokyo Night, Dracula, and more — or create your own look."
        ),
        (
            "doc.plaintext",
            "Configure via TOML",
            "Edit ~/.glance-config.toml to customize widgets, layout, and appearance. Changes apply instantly."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                .padding(.bottom, 20)

            // Page content
            let page = pages[currentPage]

            Image(systemName: page.icon)
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 6)

            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Page dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.bottom, 24)

            // Button
            if currentPage < pages.count - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPage += 1
                    }
                } label: {
                    Text("Continue")
                        .frame(width: 200)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    onDismiss()
                } label: {
                    Text("Get Started")
                        .frame(width: 200)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(width: 480, height: 420)
    }
}
