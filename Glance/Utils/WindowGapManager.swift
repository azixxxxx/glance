import Cocoa

/// Monitors all application windows via the Accessibility API and adjusts any window
/// whose top edge overlaps the Glance status bar, pushing it down with a small gap.
///
/// Requires Accessibility permission — prompts the user on first launch if not granted.
final class WindowGapManager {
    static let shared = WindowGapManager()

    private var observers: [pid_t: AXObserver] = [:]
    private var isRunning = false
    private let myPID = ProcessInfo.processInfo.processIdentifier

    /// Minimum Y (in AX top-left coordinates) where a window's top edge may sit.
    private var threshold: CGFloat {
        ConfigManager.shared.config.experimental.foreground.resolveHeight() + 6
    }

    func start() {
        guard !isRunning else { return }
        guard AXIsProcessTrusted() else {
            promptForAccessibility()
            return
        }
        isRunning = true

        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            registerObserver(for: app.processIdentifier)
        }

        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(appLaunched(_:)),
                           name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(appTerminated(_:)),
                           name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }

    // MARK: - App Lifecycle

    @objc private func appLaunched(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              app.activationPolicy == .regular else { return }
        registerObserver(for: app.processIdentifier)
    }

    @objc private func appTerminated(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        unregisterObserver(for: app.processIdentifier)
    }

    // MARK: - AX Observers

    private func registerObserver(for pid: pid_t) {
        guard pid != myPID, observers[pid] == nil else { return }

        var obs: AXObserver?
        guard AXObserverCreate(pid, windowGapAXCallback, &obs) == .success,
              let observer = obs else { return }

        let appElement = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        let notifications: [String] = [
            kAXWindowResizedNotification,
            kAXWindowMovedNotification,
            kAXWindowCreatedNotification,
            kAXFocusedWindowChangedNotification,
        ]
        for notif in notifications {
            AXObserverAddNotification(observer, appElement, notif as CFString, refcon)
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        observers[pid] = observer
    }

    private func unregisterObserver(for pid: pid_t) {
        guard let obs = observers.removeValue(forKey: pid) else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(obs), .defaultMode)
    }

    // MARK: - Event Handling

    fileprivate func handleWindowEvent(_ element: AXUIElement, notification: String) {
        if notification == kAXWindowCreatedNotification {
            // Newly created windows may not have their final frame yet.
            // ARC retains the AXUIElement when captured by the closure.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.resolveAndAdjust(element)
            }
        } else {
            resolveAndAdjust(element)
        }
    }

    private func resolveAndAdjust(_ element: AXUIElement) {
        var roleRef: AnyObject?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef) == .success,
              let role = roleRef as? String else { return }

        if role == (kAXWindowRole as String) {
            adjustIfOverlapping(element)
        } else {
            // Element might be an application — try its focused window.
            var windowRef: AnyObject?
            if AXUIElementCopyAttributeValue(element, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
               let win = windowRef {
                adjustIfOverlapping(win as! AXUIElement)
            }
        }
    }

    /// Checks whether the given window overlaps the Glance bar area and, if so,
    /// pushes it down and shrinks its height to maintain a gap.
    private func adjustIfOverlapping(_ window: AXUIElement) {
        // Skip full-screen windows (green-button full screen, not zoom).
        var fsRef: AnyObject?
        if AXUIElementCopyAttributeValue(window, "AXFullScreen" as CFString, &fsRef) == .success,
           (fsRef as? Bool) == true { return }

        // --- Position (AX coordinate system: origin at top-left of main display) ---
        var posRef: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success else { return }
        var pos = CGPoint.zero
        guard AXValueGetValue(posRef as! AXValue, .cgPoint, &pos) else { return }

        let t = threshold
        guard pos.y < t else { return }

        // --- Size ---
        var sizeRef: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success else { return }
        var size = CGSize.zero
        guard AXValueGetValue(sizeRef as! AXValue, .cgSize, &size) else { return }

        let delta = t - pos.y
        var newPos  = CGPoint(x: pos.x, y: t)
        var newSize = CGSize(width: size.width, height: max(size.height - delta, 100))

        if let pv = AXValueCreate(.cgPoint, &newPos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, pv)
        }
        if let sv = AXValueCreate(.cgSize, &newSize) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sv)
        }
    }

    // MARK: - Accessibility Permission

    private func promptForAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)

        // Poll until the user grants permission.
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                self?.start()
            }
        }
    }
}

// MARK: - C-convention AXObserver callback

private func windowGapAXCallback(
    _ observer: AXObserver,
    _ element: AXUIElement,
    _ notification: CFString,
    _ refcon: UnsafeMutableRawPointer?
) {
    guard let refcon = refcon else { return }
    let manager = Unmanaged<WindowGapManager>.fromOpaque(refcon).takeUnretainedValue()
    manager.handleWindowEvent(element, notification: notification as String)
}
