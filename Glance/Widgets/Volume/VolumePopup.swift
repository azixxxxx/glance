import SwiftUI

struct VolumePopup: View {
    @ObservedObject var viewModel: VolumeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: viewModel.volumeIconName)
                    .padding(8)
                    .background(
                        viewModel.isMuted
                            ? Color.red.opacity(0.8) : Color.blue.opacity(0.8)
                    )
                    .clipShape(Circle())
                    .foregroundStyle(.white)

                Text("\(viewModel.volumePercent)%")
                    .foregroundColor(.white)
                    .font(.headline)
            }

            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))

                Slider(
                    value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.setVolume(Float($0)) }
                    ),
                    in: 0...1
                )
                .tint(.blue)

                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }

            Button(action: { viewModel.toggleMute() }) {
                HStack {
                    Image(
                        systemName: viewModel.isMuted
                            ? "speaker.slash" : "speaker.wave.2"
                    )
                    Text(viewModel.isMuted ? "Unmute" : "Mute")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
        }
        .frame(width: 220)
        .padding(25)
        .background(Color.clear)
    }
}

struct VolumePopup_Previews: PreviewProvider {
    static var previews: some View {
        VolumePopup(viewModel: VolumeViewModel())
            .previewLayout(.sizeThatFits)
    }
}
