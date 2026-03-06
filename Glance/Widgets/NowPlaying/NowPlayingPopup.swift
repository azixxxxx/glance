import SwiftUI

struct NowPlayingPopup: View {
    @ObservedObject var configProvider: ConfigProvider
    @ObservedObject private var playingManager = NowPlayingManager.shared
    @ObservedObject var configManager = ConfigManager.shared
    var appearance: AppearanceConfig { configManager.config.appearance }

    var body: some View {
        if let song = playingManager.nowPlaying,
           let duration = song.duration,
           let position = song.position {
            VStack(spacing: 0) {
                // Album art — large, centered
                RotateAnimatedCachedImage(
                    url: song.albumArtURL,
                    targetSize: CGSize(width: 400, height: 400)
                ) { image in
                    image.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .frame(width: 220, height: 220)
                .scaleEffect(song.state == .paused ? 0.95 : 1)
                .opacity(song.state == .paused ? 0.7 : 1)
                .animation(.smooth(duration: 0.4), value: song.state == .paused)
                .padding(.bottom, 16)

                // Track info
                VStack(spacing: 3) {
                    Text(song.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)

                    Text(song.artist)
                        .font(.system(size: 13))
                        .opacity(0.6)
                        .lineLimit(1)

                    // Album name
                    if !song.album.isEmpty {
                        Text(song.album)
                            .font(.system(size: 12))
                            .opacity(0.4)
                            .lineLimit(1)
                            .padding(.top, 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 14)

                // Animated progress bar
                SmoothProgressBar(
                    position: position,
                    duration: duration,
                    isPlaying: song.state == .playing,
                    accentColor: appearance.accentColor,
                    trackColor: appearance.foregroundColor.opacity(0.15)
                )
                .padding(.bottom, 4)

                // Time labels
                HStack {
                    Text(timeString(from: position))
                    Spacer()
                    Text("-" + timeString(from: duration - position))
                }
                .font(.caption2)
                .monospacedDigit()
                .opacity(0.4)
                .padding(.bottom, 16)

                // Playback controls
                HStack(spacing: 36) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 16))
                        .opacity(0.7)
                        .onTapGesture { playingManager.previousTrack() }
                    Image(systemName: song.state == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .onTapGesture { playingManager.togglePlayPause() }
                    Image(systemName: "forward.fill")
                        .font(.system(size: 16))
                        .opacity(0.7)
                        .onTapGesture { playingManager.nextTrack() }
                }
            }
            .padding(22)
            .frame(width: 264)
            .animation(.easeInOut, value: song.albumArtURL)
        }
    }
}

// MARK: - Smooth Progress Bar

/// A progress bar that smoothly animates between position updates.
private struct SmoothProgressBar: View {
    let position: Double
    let duration: Double
    let isPlaying: Bool
    let accentColor: Color
    let trackColor: Color

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(trackColor)
                    .frame(height: 3)

                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: geo.size.width * animatedProgress, height: 3)

                // Knob
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .offset(x: max(0, geo.size.width * animatedProgress - 4))
                    .shadow(color: accentColor.opacity(0.4), radius: 4)
            }
        }
        .frame(height: 8)
        .onAppear {
            animatedProgress = CGFloat(position / max(duration, 1))
        }
        .onChange(of: position) { _, newPosition in
            withAnimation(.linear(duration: isPlaying ? 0.3 : 0)) {
                animatedProgress = CGFloat(newPosition / max(duration, 1))
            }
        }
    }
}

private func timeString(from seconds: Double) -> String {
    let intSeconds = Int(seconds)
    let minutes = intSeconds / 60
    let remainingSeconds = intSeconds % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
}
