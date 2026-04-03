import AppKit
import SwiftUI

// MARK: - Parallelogram shape for skewed cards

private struct ParallelogramShape: Shape {
    var skewOffset: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + skewOffset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - skewOffset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Per-wallpaper state

private final class WallpaperCardState: ObservableObject {
    @Published var palette: WallpaperPalette?
    @Published var thumbnail: NSImage?
    private var task: Task<Void, Never>?

    func load(url: URL) {
        guard thumbnail == nil else { return }
        task?.cancel()
        task = Task.detached(priority: .utility) { [weak self] in
            guard let img = NSImage(contentsOf: url) else { return }
            let thumb = Self.resize(img, to: CGSize(width: 400, height: 260))
            let palette = WallpaperColorExtractor.extract(from: url)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.thumbnail = thumb
                self?.palette = palette
            }
        }
    }

    private static func resize(_ image: NSImage, to size: CGSize) -> NSImage {
        let result = NSImage(size: size)
        result.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy, fraction: 1)
        result.unlockFocus()
        return result
    }
}

// MARK: - Mini bar preview (real widgets look-alike)

private struct MiniBarPreview: View {
    let appearance: AppearanceConfig

    private var widgetItems: [(String, String)] {
        [("rectangle.grid.1x2", "Spaces"),
         ("photo", "App"),
         ("waveform", "Music"),
         ("wifi", ""),
         ("battery.75", ""),
         ("clock", "14:30")]
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(widgetItems, id: \.0) { (icon, label) in
                HStack(spacing: 3) {
                    Image(systemName: icon)
                        .font(.system(size: 8, weight: .medium))
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 8, weight: .medium))
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, label.isEmpty ? 5 : 7)
                .padding(.vertical, 4)
                .background(
                    appearance.widgetBackgroundColor.opacity(appearance.fillOpacity)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            appearance.borderColor.opacity(appearance.borderTopOpacity),
                            lineWidth: appearance.borderWidth * 0.6
                        )
                )
                .foregroundStyle(appearance.foregroundColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - Single wallpaper card

private struct WallpaperCard: View {
    let url: URL
    let isActive: Bool
    let onTap: (WallpaperPalette?) -> Void

    @StateObject private var state = WallpaperCardState()
    @State private var isHovered = false

    private let cardW: CGFloat = 200
    private let cardH: CGFloat = 128
    private let skewOffset: CGFloat = 14

    var body: some View {
        Button(action: { onTap(state.palette) }) {
            ZStack(alignment: .bottom) {
                // Image clipped to parallelogram
                Group {
                    if let thumb = state.thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(.quaternary)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                            )
                    }
                }
                .frame(width: cardW, height: cardH)
                .clipShape(ParallelogramShape(skewOffset: skewOffset))

                // Mini bar preview overlay at the bottom
                if let palette = state.palette {
                    let appearance = palette.toAppearanceConfig()
                    VStack(spacing: 0) {
                        Spacer()
                        MiniBarPreview(appearance: appearance)
                            .frame(width: cardW, height: 28)
                            .background(
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .frame(width: cardW, height: cardH)
                    .clipShape(ParallelogramShape(skewOffset: skewOffset))
                }

                // Color palette dots
                if let palette = state.palette {
                    HStack(spacing: 4) {
                        ForEach(Array(palette.allColors.prefix(5).enumerated()), id: \.offset) { _, color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 8, height: 8)
                                .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 0.5))
                        }
                    }
                    .padding(.bottom, 6)
                    .padding(.leading, skewOffset / 2)
                }

                // Selection ring
                if isActive {
                    ParallelogramShape(skewOffset: skewOffset)
                        .stroke(Color.accentColor, lineWidth: 2.5)
                        .frame(width: cardW, height: cardH)
                }

                // Hover highlight
                if isHovered && !isActive {
                    ParallelogramShape(skewOffset: skewOffset)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: cardW, height: cardH)
                }
            }
            .frame(width: cardW, height: cardH)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .onAppear { state.load(url: url) }
        .help(url.deletingPathExtension().lastPathComponent)
    }
}

// MARK: - Main picker view

struct WallpaperPickerView: View {
    @ObservedObject private var themeManager = WallpaperThemeManager.shared
    @State private var wallpaperURLs: [URL] = []
    @State private var currentWallpaperURL: URL?
    @State private var selectedFolderURL: URL?
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 220), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Wallpaper Theme")
                        .font(.title2.bold())
                    Text("Pick a wallpaper — bar colors adapt automatically")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("Adaptive Colors", isOn: Binding(
                    get: { themeManager.isEnabled },
                    set: { enabled in
                        if enabled { themeManager.enable() }
                        else { themeManager.disable() }
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Folder bar
            HStack(spacing: 12) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(selectedFolderURL?.lastPathComponent ?? "macOS Wallpapers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Choose Folder...") { chooseFolderFromPicker() }
                    .controlSize(.small)
                Button("Refresh") { loadWallpapers() }
                    .controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)

            Divider()

            // Grid
            if wallpaperURLs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundStyle(.quaternary)
                    Text("No wallpapers found")
                        .foregroundStyle(.secondary)
                    Button("Choose a folder with images") { chooseFolderFromPicker() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(wallpaperURLs, id: \.absoluteString) { url in
                            WallpaperCard(
                                url: url,
                                isActive: currentWallpaperURL == url
                            ) { palette in
                                setWallpaper(url: url, palette: palette)
                            }
                        }
                    }
                    .padding(24)
                }
            }

            Divider()

            // Footer
            HStack {
                if themeManager.isEnabled {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Adaptive colors active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(width: 740, height: 540)
        .background(.background)
        .onAppear {
            currentWallpaperURL = currentSystemWallpaper()
            loadWallpapers()
        }
    }

    // MARK: - Actions

    private func setWallpaper(url: URL, palette: WallpaperPalette?) {
        // Set the system wallpaper
        if let screen = NSScreen.main {
            try? NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        }
        currentWallpaperURL = url

        // Immediately apply palette (don't wait for notification)
        if let palette = palette, themeManager.isEnabled {
            themeManager.applyPalette(palette)
        } else if let palette = palette {
            themeManager.enable()
            themeManager.applyPalette(palette)
        }
    }

    private func chooseFolderFromPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder containing wallpaper images"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        selectedFolderURL = url
        loadWallpapers()
    }

    private func loadWallpapers() {
        let folder = selectedFolderURL ?? defaultWallpaperFolder()
        guard let folder else { wallpaperURLs = []; return }

        let fm = FileManager.default
        let extensions = Set(["jpg", "jpeg", "png", "heic", "tiff", "webp"])
        guard let enumerator = fm.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        var urls: [URL] = []
        for case let url as URL in enumerator {
            if extensions.contains(url.pathExtension.lowercased()) {
                urls.append(url)
            }
        }
        wallpaperURLs = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func defaultWallpaperFolder() -> URL? {
        // macOS system wallpapers
        let path = "/Library/Desktop Pictures"
        if FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    private func currentSystemWallpaper() -> URL? {
        guard let screen = NSScreen.main else { return nil }
        return NSWorkspace.shared.desktopImageURL(for: screen)
    }
}
