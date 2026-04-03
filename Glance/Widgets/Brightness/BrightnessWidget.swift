import SwiftUI

struct BrightnessWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @StateObject private var viewModel = BrightnessViewModel()
    @State private var rect: CGRect = .zero

    private var showPercentage: Bool {
        configProvider.config["show-percentage"]?.boolValue ?? false
    }

    private var scrollStep: Float {
        let configuredStep = configProvider.config["scroll-step"]?.doubleValue ?? 3
        return Float(max(1, min(15, configuredStep))) / 100
    }

    var body: some View {
        Group {
            if viewModel.isAvailable {
                HStack(spacing: 5) {
                    Image(systemName: viewModel.iconName)
                        .barStatusSymbol(opticalYOffset: -0.15)
                    if showPercentage {
                        Text("\(viewModel.brightnessPercent)%")
                            .font(.system(size: 13, weight: .medium))
                            .monospacedDigit()
                    }
                }
                .barSingleLineAligned()
                .shadow(color: .black.opacity(0.3), radius: 3)
            } else {
                Image(systemName: "sun.max")
                    .barStatusSymbol(opticalYOffset: -0.15)
                    .foregroundStyle(.secondary)
                    .shadow(color: .black.opacity(0.3), radius: 3)
            }
        }
        .experimentalConfiguration(horizontalPadding: 8)
        .frame(maxHeight: .infinity)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { rect = geo.frame(in: .global) }
                    .onChange(of: geo.frame(in: .global)) { _, newValue in
                        rect = newValue
                    }
            }
        )
        .background(.black.opacity(0.001))
        .overlay(
            viewModel.isAvailable
                ? AnyView(BrightnessScrollOverlay { delta in
                    viewModel.adjustBrightness(by: delta > 0 ? -scrollStep : scrollStep)
                })
                : AnyView(EmptyView())
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    FeedbackManager.shared.tock()
                    MenuBarPopup.show(rect: rect, id: "brightness-actions") {
                        QuickActionsView(title: "Brightness", actions: [
                            QuickAction(icon: "sun.min", label: "25%") { viewModel.setBrightness(0.25) },
                            QuickAction(icon: "sun.min.fill", label: "50%") { viewModel.setBrightness(0.50) },
                            QuickAction(icon: "sun.max", label: "75%") { viewModel.setBrightness(0.75) },
                            QuickAction(icon: "sun.max.fill", label: "100%") { viewModel.setBrightness(1.0) },
                        ])
                    }
                }
        )
        .onTapGesture {
            MenuBarPopup.show(rect: rect, id: "brightness") {
                BrightnessPopup(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Scroll Overlay (same pattern as VolumeScrollOverlay)

private struct BrightnessScrollOverlay: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> BrightnessScrollNSView {
        let view = BrightnessScrollNSView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: BrightnessScrollNSView, context: Context) {
        nsView.onScroll = onScroll
    }
}

final class BrightnessScrollNSView: NSView {
    var onScroll: ((CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        onScroll?(event.deltaY)
    }

    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        nextResponder?.mouseUp(with: event)
    }
}

struct BrightnessWidget_Previews: PreviewProvider {
    static var previews: some View {
        BrightnessWidget()
            .frame(width: 200, height: 100)
            .background(Color.black)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
