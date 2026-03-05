import AppKit
import CoreGraphics

// MARK: - Private CoreGraphics API

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> Int

@_silgen_name("CGSCopyManagedDisplaySpaces")
private func CGSCopyManagedDisplaySpaces(_ conn: Int) -> CFArray

@_silgen_name("CGSCopySpacesForWindows")
private func CGSCopySpacesForWindows(_ conn: Int, _ mask: Int, _ windowIDs: CFArray) -> CFArray?

// MARK: - Native Spaces Provider

class NativeSpacesProvider: SpacesProvider, SwitchableSpacesProvider {
    typealias SpaceType = NativeSpace

    /// Cached windows per space ID — updated each time a space is focused.
    private var windowCache: [Int: [NativeWindow]] = [:]

    /// Tracks the previous poll's space ID to detect transitions.
    private var lastSeenSpaceID: Int?

    /// Serializes access to windowCache — called from concurrent GCD threads.
    private let lock = NSLock()

    /// Set of regular (foreground) app names, rebuilt on each poll.
    private func regularAppNames() -> Set<String> {
        Set(
            NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular }
                .compactMap { $0.localizedName }
        )
    }

    func getSpacesWithWindows() -> [NativeSpace]? {
        lock.lock()
        defer { lock.unlock() }

        let conn = CGSMainConnectionID()
        guard
            let displaySpaces = CGSCopyManagedDisplaySpaces(conn)
                as? [[String: Any]],
            let mainDisplay = displaySpaces.first
        else {
            return nil
        }

        guard
            let spaces = mainDisplay["Spaces"] as? [[String: Any]],
            let currentSpace = mainDisplay["Current Space"]
                as? [String: Any]
        else {
            return nil
        }

        let currentSpaceID = intValue(currentSpace["ManagedSpaceID"])

        let userSpaces = spaces.filter {
            let t = intValue($0["type"]) ?? -1
            return t == 0 || t == 4
        }

        let onScreenWindows = getOnScreenWindows()

        // Cache the focused space's windows — but only after verifying
        // that on-screen windows actually belong to this space.
        // During a space transition, CGS reports the new space before
        // the on-screen window list updates, causing a mismatch.
        if let cid = currentSpaceID {
            if let firstWindow = onScreenWindows.first {
                let wSpaces = CGSCopySpacesForWindows(
                    conn, 0x7, [firstWindow.id] as CFArray)
                    as? [NSNumber] ?? []
                if wSpaces.contains(where: { $0.intValue == cid }) {
                    windowCache[cid] = onScreenWindows
                }
            } else {
                // No windows — safe to cache empty.
                windowCache[cid] = []
            }
        }

        // Collect all user space IDs for cache bootstrapping.
        let allSpaceIDs = Set(
            userSpaces.compactMap { intValue($0["ManagedSpaceID"]) })
        // Remove stale cache entries for spaces that no longer exist.
        for key in windowCache.keys where !allSpaceIDs.contains(key) {
            windowCache.removeValue(forKey: key)
        }

        // Bootstrap: for spaces we've never visited, do a one-time lookup.
        bootstrapUncachedSpaces(
            conn: conn, userSpaces: userSpaces,
            currentSpaceID: currentSpaceID)

        var result: [NativeSpace] = []
        for (index, space) in userSpaces.enumerated() {
            let spaceID = intValue(space["ManagedSpaceID"])
            guard let spaceID else { continue }

            let isFocused = spaceID == currentSpaceID
            let spaceNumber = index + 1

            let spaceWindows: [NativeWindow]
            if isFocused {
                spaceWindows = onScreenWindows
            } else if let pid = intValue(space["pid"]) {
                // Fullscreen space — get the owning app via its PID.
                spaceWindows = windowFromPid(pid_t(pid))
            } else {
                spaceWindows = windowCache[spaceID] ?? []
            }

            result.append(
                NativeSpace(
                    id: spaceID,
                    spaceNumber: spaceNumber,
                    isFocused: isFocused,
                    windows: spaceWindows
                ))
        }

        return result
    }

    func focusSpace(spaceId: String, needWindowFocus: Bool) {
        guard let spaceNumber = Int(spaceId), spaceNumber >= 1 else { return }

        let conn = CGSMainConnectionID()
        guard
            let displaySpaces = CGSCopyManagedDisplaySpaces(conn)
                as? [[String: Any]],
            let mainDisplay = displaySpaces.first,
            let spaces = mainDisplay["Spaces"] as? [[String: Any]],
            let currentSpace = mainDisplay["Current Space"]
                as? [String: Any],
            let currentSpaceID = intValue(
                currentSpace["ManagedSpaceID"])
        else { return }

        let userSpaces = spaces.filter {
            let t = intValue($0["type"]) ?? -1
            return t == 0 || t == 4
        }

        guard spaceNumber <= userSpaces.count,
            let targetSpaceID = intValue(
                userSpaces[spaceNumber - 1]["ManagedSpaceID"])
        else { return }

        if targetSpaceID == currentSpaceID { return }

        // Find a window exclusively on the target space and activate its app.
        // macOS will automatically switch to the space containing that window.
        guard
            let windowList = CGWindowListCopyWindowInfo(
                [.excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]]
        else { return }

        for info in windowList {
            guard
                let windowID = info[kCGWindowNumber as String] as? Int,
                let layer = info[kCGWindowLayer as String] as? Int,
                layer == 0,
                let pid = info[kCGWindowOwnerPID as String] as? Int
            else { continue }

            guard
                let windowSpaces = CGSCopySpacesForWindows(
                    conn, 0x7, [windowID] as CFArray) as? [NSNumber]
            else { continue }

            // Only pick a window that is exclusively on the target space.
            if windowSpaces.count == 1
                && windowSpaces.first?.intValue == targetSpaceID
            {
                let app = NSRunningApplication(
                    processIdentifier: pid_t(pid))
                app?.activate(options: [.activateIgnoringOtherApps])
                return
            }
        }
    }

    func focusWindow(windowId: String) {
        guard let wid = Int(windowId) else { return }

        guard
            let windowList = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID) as? [[String: Any]]
        else { return }

        for info in windowList {
            guard
                let num = info[kCGWindowNumber as String] as? Int,
                num == wid,
                let pid = info[kCGWindowOwnerPID as String] as? Int
            else { continue }

            let app = NSRunningApplication(
                processIdentifier: pid_t(pid))
            app?.activate(options: [.activateIgnoringOtherApps])
            return
        }
    }

    // MARK: - Helpers

    private func intValue(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let n = value as? NSNumber { return n.intValue }
        return nil
    }

    private func windowFromPid(_ pid: pid_t) -> [NativeWindow] {
        guard let app = NSRunningApplication(processIdentifier: pid),
            let name = app.localizedName
        else { return [] }

        var icon: NSImage? = nil
        if let url = app.bundleURL {
            icon = NSWorkspace.shared.icon(forFile: url.path)
        }

        return [
            NativeWindow(
                id: Int(pid),
                title: name,
                appName: name,
                isFocused: false,
                appIcon: icon
            )
        ]
    }

    // MARK: - Bootstrap

    /// One-time lookup for spaces we haven't visited yet.
    /// Uses CGSCopySpacesForWindows with strict filtering:
    /// only windows exclusively on ONE space (not sticky/global).
    private func bootstrapUncachedSpaces(
        conn: Int, userSpaces: [[String: Any]], currentSpaceID: Int?
    ) {
        let uncachedIDs = userSpaces.compactMap {
            intValue($0["ManagedSpaceID"])
        }.filter {
            $0 != currentSpaceID && windowCache[$0] == nil
        }
        guard !uncachedIDs.isEmpty else { return }

        guard
            let windowList = CGWindowListCopyWindowInfo(
                [.excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]]
        else { return }

        let allowed = regularAppNames()
        let systemApps: Set<String> = [
            "Window Server", "Dock", "SystemUIServer", "Control Center",
            "Notification Center", "Spotlight", "Glance",
        ]
        let uncachedSet = Set(uncachedIDs)
        var seenPerSpace: [Int: Set<String>] = [:]

        for info in windowList {
            guard
                let windowID = info[kCGWindowNumber as String] as? Int,
                let ownerName = info[kCGWindowOwnerName as String]
                    as? String,
                let layer = info[kCGWindowLayer as String] as? Int,
                layer == 0
            else { continue }

            if systemApps.contains(ownerName) { continue }
            if !allowed.contains(ownerName) { continue }

            guard
                let spaceIDs = CGSCopySpacesForWindows(
                    conn, 0x7, [windowID] as CFArray) as? [NSNumber]
            else { continue }

            // Strict: only windows that belong to exactly ONE user space.
            // This filters out sticky/global windows that appear on all spaces.
            let matchingUserSpaces = spaceIDs.filter {
                uncachedSet.contains($0.intValue)
            }
            guard matchingUserSpaces.count == 1,
                let sid = matchingUserSpaces.first?.intValue
            else { continue }

            if seenPerSpace[sid] == nil { seenPerSpace[sid] = Set() }
            if seenPerSpace[sid]!.contains(ownerName) { continue }
            seenPerSpace[sid]!.insert(ownerName)

            let title = info[kCGWindowName as String] as? String ?? ""
            var window = NativeWindow(
                id: windowID,
                title: title,
                appName: ownerName,
                isFocused: false,
                appIcon: nil
            )
            window.appIcon = IconCache.shared.icon(for: ownerName)

            if windowCache[sid] == nil { windowCache[sid] = [] }
            windowCache[sid]!.append(window)
        }

        // Mark remaining uncached spaces as empty (so bootstrap doesn't retry).
        for sid in uncachedIDs where windowCache[sid] == nil {
            windowCache[sid] = []
        }
    }

    // MARK: - Window List

    private func getOnScreenWindows() -> [NativeWindow] {
        guard
            let windowList = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID) as? [[String: Any]]
        else {
            return []
        }

        let focusedApp = NSWorkspace.shared.frontmostApplication
        let allowed = regularAppNames()

        let systemApps: Set<String> = [
            "Window Server", "Dock", "SystemUIServer", "Control Center",
            "Notification Center", "Spotlight", "Glance",
        ]

        var seenApps = Set<String>()

        return windowList.compactMap { info -> NativeWindow? in
            guard
                let windowID = info[kCGWindowNumber as String] as? Int,
                let ownerName = info[kCGWindowOwnerName as String]
                    as? String,
                let layer = info[kCGWindowLayer as String] as? Int,
                layer == 0
            else { return nil }

            if systemApps.contains(ownerName) { return nil }
            if !allowed.contains(ownerName) { return nil }

            if seenApps.contains(ownerName) { return nil }
            seenApps.insert(ownerName)

            let title = info[kCGWindowName as String] as? String ?? ""
            let isFocused = focusedApp?.localizedName == ownerName

            var window = NativeWindow(
                id: windowID,
                title: title,
                appName: ownerName,
                isFocused: isFocused,
                appIcon: nil
            )

            window.appIcon = IconCache.shared.icon(for: ownerName)
            return window
        }
    }
}
