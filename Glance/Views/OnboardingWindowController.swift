import SwiftUI

final class OnboardingWindowController {
    static let shared = OnboardingWindowController()

    private static let hasSeenOnboardingKey = "hasSeenOnboarding"
    private var window: NSWindow?

    private init() {}

    var shouldShowOnboarding: Bool {
        !UserDefaults.standard.bool(forKey: Self.hasSeenOnboardingKey)
    }

    func showIfNeeded() {
        guard shouldShowOnboarding else { return }
        show()
    }

    func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let onboardingView = OnboardingView {
            self.dismiss()
        }
        let hostingView = NSHostingView(rootView: onboardingView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Welcome to Glance"
        newWindow.contentView = hostingView
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)

        NSApp.activate()

        self.window = newWindow
    }

    private func dismiss() {
        UserDefaults.standard.set(true, forKey: Self.hasSeenOnboardingKey)
        window?.close()
        window = nil
    }
}
