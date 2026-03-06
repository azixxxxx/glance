import ServiceManagement
import SwiftUI

/// NSHostingView subclass that enables vibrancy for glass effects.
class GlanceHostingView<Content: View>: NSHostingView<Content> {
    override var allowsVibrancy: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var backgroundPanel: NSPanel?
    private var menuBarPanel: NSPanel?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let error = ConfigManager.shared.initError {
            showFatalConfigError(message: error)
            return
        }

        // Show "What's New" banner if the app version is outdated
        if !VersionChecker.isLatestVersion() {
            VersionChecker.updateVersionFile()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(
                    name: Notification.Name("ShowWhatsNewBanner"), object: nil)
            }
        }

        MenuBarPopup.setup()
        setupPanels()
        setupStatusItem()
        WindowGapManager.shared.start()

        // Show onboarding on first launch
        OnboardingWindowController.shared.showIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
    }

    @objc private func screenParametersDidChange(_ notification: Notification) {
        setupPanels()
    }

    // MARK: - Status Item (Tray Icon)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Glance")
            image?.size = NSSize(width: 18, height: 18)
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Glance"
        }

        let menu = NSMenu()

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Launch at Login
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = isLaunchAtLoginEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Glance", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showSettings()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let service = SMAppService.mainApp
        do {
            if isLaunchAtLoginEnabled {
                try service.unregister()
                sender.state = .off
            } else {
                try service.register()
                sender.state = .on
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    // MARK: - Panels

    /// Configures and displays the background and menu bar panels.
    private func setupPanels() {
        guard let screenFrame = NSScreen.main?.frame else { return }
        setupPanel(
            &backgroundPanel,
            frame: screenFrame,
            level: Int(CGWindowLevelForKey(.desktopWindow)),
            hostingRootView: AnyView(BackgroundView()))
        setupPanel(
            &menuBarPanel,
            frame: screenFrame,
            level: Int(CGWindowLevelForKey(.backstopMenu)),
            hostingRootView: AnyView(MenuBarView()))
    }

    /// Sets up an NSPanel with the provided parameters.
    private func setupPanel(
        _ panel: inout NSPanel?, frame: CGRect, level: Int,
        hostingRootView: AnyView
    ) {
        if let existingPanel = panel {
            existingPanel.setFrame(frame, display: true)
            return
        }

        let newPanel = NSPanel(
            contentRect: frame,
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false)
        newPanel.level = NSWindow.Level(rawValue: level)
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.collectionBehavior = [.canJoinAllSpaces]
        newPanel.titlebarAppearsTransparent = true

        let hostingView = GlanceHostingView(rootView: hostingRootView)
        newPanel.contentView = hostingView

        newPanel.orderFront(nil)
        panel = newPanel
    }

    private func showFatalConfigError(message: String) {
        let alert = NSAlert()
        alert.messageText = "Configuration Error"
        alert.informativeText = "\(message)\n\nPlease double check ~/.glance-config.toml and try again."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Quit")

        alert.runModal()
        NSApplication.shared.terminate(nil)
    }
}
