import SwiftUI

struct VolumePopup: View {
    @ObservedObject var viewModel: VolumeViewModel
    @ObservedObject var configManager = ConfigManager.shared
    var appearance: AppearanceConfig { configManager.config.appearance }

    var body: some View {
        VStack(spacing: 14) {
            // Volume percentage
            HStack {
                Image(systemName: viewModel.volumeIconName)
                    .font(.system(size: 14))
                    .foregroundStyle(viewModel.isMuted ? .red : appearance.accentColor)
                Text(viewModel.isMuted ? "Muted" : "\(viewModel.volumePercent)%")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Slider
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .opacity(0.4)

                Slider(
                    value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.setVolume(Float($0)) }
                    ),
                    in: 0...1
                )
                .tint(appearance.accentColor)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .opacity(0.4)
            }

            // Mute button
            Button(action: { viewModel.toggleMute() }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isMuted ? "speaker.slash" : "speaker.wave.2")
                        .font(.system(size: 11))
                    Text(viewModel.isMuted ? "Unmute" : "Mute")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(appearance.foregroundColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            // Output device
            if !viewModel.outputDeviceName.isEmpty {
                Divider().opacity(0.15)

                HStack(spacing: 8) {
                    Image(systemName: viewModel.outputDeviceIcon)
                        .font(.system(size: 11))
                        .opacity(0.5)
                    Text(viewModel.outputDeviceName)
                        .font(.system(size: 12))
                        .opacity(0.6)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .frame(width: 200)
        .padding(22)
    }
}
