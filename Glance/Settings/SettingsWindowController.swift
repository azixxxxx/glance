import SwiftUI

/// Manages the Settings window lifecycle.
/// Since Glance is an LSUIElement app (no Dock icon), we manage
/// the Settings window manually via NSWindow.
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func showSettings() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Glance Settings"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.setFrameAutosaveName("GlanceSettings")
        newWindow.minSize = NSSize(width: 560, height: 400)
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        NSApp.activate()

        self.window = newWindow
    }
}
