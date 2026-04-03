import SwiftUI

struct VolumeWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @StateObject private var viewModel = VolumeViewModel()
    @State private var rect: CGRect = .zero
    @State private var showScrollFeedback = false
    @State private var feedbackDismissTask: Task<Void, Never>?

    private var showPercentage: Bool {
        configProvider.config["show-percentage"]?.boolValue ?? false
    }

    private var scrollStep: Float {
        let configuredStep = configProvider.config["scroll-step"]?.doubleValue ?? 3
        return Float(max(1, min(15, configuredStep))) / 100
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: viewModel.volumeIconName)
                .barStatusSymbol(opticalYOffset: -0.2)
            if showPercentage {
                Text(viewModel.isMuted ? "Mute" : "\(viewModel.volumePercent)%")
                    .font(.system(size: 13, weight: .medium))
                    .monospacedDigit()
            }
        }
        .barSingleLineAligned()
        .shadow(color: .black.opacity(0.3), radius: 3)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { rect = geometry.frame(in: .global) }
                        .onChange(of: geometry.frame(in: .global)) { _, newValue in
                            rect = newValue
                        }
                }
            )
            .contentShape(Rectangle())
            .experimentalConfiguration()
            .frame(maxHeight: .infinity)
            .background(.black.opacity(0.001))
            .overlay(
                VolumeScrollOverlay { delta in
                    viewModel.adjustVolume(by: delta > 0 ? -scrollStep : scrollStep)
                    FeedbackManager.shared.tick()
                    showScrollFeedback = true
                    feedbackDismissTask?.cancel()
                    feedbackDismissTask = Task {
                        try? await Task.sleep(for: .seconds(1))
                        guard !Task.isCancelled else { return }
                        await MainActor.run { showScrollFeedback = false }
                    }
                }
            )
            .overlay(
                Group {
                    if showScrollFeedback && !showPercentage {
                        Text(viewModel.isMuted ? "Mute" : "\(viewModel.volumePercent)%")
                            .font(.system(size: 11, weight: .semibold))
                            .monospacedDigit()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .animation(showScrollFeedback ? .easeOut(duration: 0.15) : .easeIn(duration: 0.3), value: showScrollFeedback)
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        FeedbackManager.shared.tock()
                        MenuBarPopup.show(rect: rect, id: "volume-actions") {
                            QuickActionsView(title: "Volume", actions: [
                                QuickAction(
                                    icon: viewModel.isMuted ? "speaker.wave.2.fill" : "speaker.slash.fill",
                                    label: viewModel.isMuted ? "Unmute" : "Mute",
                                    isActive: viewModel.isMuted
                                ) { viewModel.toggleMute() },
                            ])
                        }
                    }
            )
            .onTapGesture {
                MenuBarPopup.show(rect: rect, id: "volume") {
                    VolumePopup(viewModel: viewModel)
                }
            }
    }
}

/// Transparent NSView overlay that captures scroll wheel events.
private struct VolumeScrollOverlay: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> VolumeScrollNSView {
        let view = VolumeScrollNSView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: VolumeScrollNSView, context: Context) {
        nsView.onScroll = onScroll
    }
}

final class VolumeScrollNSView: NSView {
    var onScroll: ((CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        onScroll?(event.deltaY)
    }

    // Forward mouse events to the responder chain so SwiftUI gestures work.
    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        nextResponder?.mouseUp(with: event)
    }
}

struct VolumeWidget_Previews: PreviewProvider {
    static var previews: some View {
        VolumeWidget()
            .frame(width: 200, height: 100)
            .background(Color.black)
            .environmentObject(ConfigProvider(config: [:]))
    }
}
