import AppKit
import Combine
import SwiftUI

final class WallpaperThemeManager: ObservableObject {
    static let shared = WallpaperThemeManager()

    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var currentPalette: WallpaperPalette?
    @Published private(set) var derivedAppearance: AppearanceConfig?

    private var notificationObserver: Any?
    private var extractionTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: "wallpaperThemeEnabled")

        // Bridge: when our derivedAppearance changes, tell ConfigManager to re-render
        $derivedAppearance
            .receive(on: DispatchQueue.main)
            .sink { _ in
                ConfigManager.shared.objectWillChange.send()
            }
            .store(in: &cancellables)

        if isEnabled {
            startMonitoring()
            extractCurrentWallpaper()
        }
    }

    // MARK: - Public API

    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        UserDefaults.standard.set(true, forKey: "wallpaperThemeEnabled")
        startMonitoring()
        extractCurrentWallpaper()
    }

    func disable() {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: "wallpaperThemeEnabled")
        stopMonitoring()
        currentPalette = nil
        derivedAppearance = nil
    }

    /// Apply a pre-extracted palette immediately (called from wallpaper picker for instant preview).
    func applyPalette(_ palette: WallpaperPalette) {
        currentPalette = palette
        derivedAppearance = palette.toAppearanceConfig()
    }

    /// Re-extract from the current system wallpaper.
    func refreshFromCurrentWallpaper() {
        extractCurrentWallpaper()
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        // System-level notification: fires when the desktop picture changes
        notificationObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.desktop.notify.changed"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.extractCurrentWallpaper()
        }
    }

    private func stopMonitoring() {
        if let obs = notificationObserver {
            DistributedNotificationCenter.default().removeObserver(obs)
            notificationObserver = nil
        }
    }

    // MARK: - Extraction

    private func extractCurrentWallpaper() {
        guard let screen = NSScreen.main,
              let url = NSWorkspace.shared.desktopImageURL(for: screen) else { return }

        extractionTask?.cancel()
        extractionTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard !Task.isCancelled else { return }
            guard let palette = WallpaperColorExtractor.extract(from: url) else { return }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.applyPalette(palette)
            }
        }
    }
}
