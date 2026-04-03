# Glance — Custom macOS Status Bar

Modern macOS status bar replacement with liquid glass UI, native Spaces support, and custom widgets.

**Version:** 1.2.1
**Author:** azixxxxx (Azim Sukhanov)
**GitHub:** https://github.com/azixxxxx/glance
**Bundle ID:** `com.azimsukhanov.glance`

## System Context

- **Hardware:** Mac Mini M4, 1080p display
- **Network:** Wi-Fi only (no Ethernet)
- **Window Manager:** Native macOS (no yabai, no AeroSpace)
- **macOS:** Sequoia
- **Config file:** `~/.glance-config.toml`
- **Deployed at:** `/Applications/Glance.app`

## Build & Deploy

```bash
# Build (from project root)
xcodebuild -project Glance.xcodeproj -scheme Glance -configuration Release \
  -derivedDataPath build build \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Deploy (MUST kill, rm -rf, then copy — cp alone won't overwrite a running app)
pkill -x Glance; sleep 2
rm -rf /Applications/Glance.app
cp -R build/Build/Products/Release/Glance.app /Applications/Glance.app
open /Applications/Glance.app

# Build DMG + ZIP for distribution
./scripts/build-dmg.sh
```

**Important:** Always `rm -rf` before `cp -R`. Otherwise the old binary may persist.

**Style files must be moved before build** — Xcode auto-discovers all `.swift` in the tree:
```bash
mkdir -p /tmp/glance-styles-backup
mv Glance/Styles/{Glass,Minimal,Solid,System}Style.swift /tmp/glance-styles-backup/
# ... build ...
cp /tmp/glance-styles-backup/*.swift Glance/Styles/
```

## Project Structure

```
Glance/
├── Info.plist                          # LSUIElement=true, Sparkle keys, Location keys
├── AppDelegate.swift                   # App lifecycle, tray icon, login item, Sparkle updater
├── GlanceApp.swift                     # SwiftUI app entry (@main)
├── Constants.swift                     # App constants
├── Config/
│   ├── ConfigManager.swift             # Config loading, file watching, live reload
│   ├── ConfigModels.swift              # RootToml, Config, style support
│   ├── AppearanceConfig.swift          # Visual params struct + resolvedCornerRadius
│   ├── PresetRegistry.swift            # 11 built-in presets (Preset enum)
│   └── CustomPresetStore.swift         # User presets in ~/Library/Application Support/glance/presets/
├── MenuBarPopup/                       # Popup infrastructure (glass background)
├── Settings/
│   ├── SettingsWindowController.swift  # NSWindow manager for Settings
│   ├── SettingsView.swift              # Tab-based settings (sidebar nav)
│   ├── PresetEditorView.swift          # Full visual preset editor (sheet)
│   └── Tabs/                           # General, Widgets, Spaces, Time, About
├── Styles/
│   ├── BarStyleProvider.swift          # Protocol + BarStyle enum + @Environment keys
│   ├── GlassStyle.swift                # Liquid glass — blur + highlight + border
│   ├── SolidStyle.swift                # Flat opaque background
│   ├── MinimalStyle.swift              # Transparent, text/icons only
│   └── SystemStyle.swift               # Native macOS .regularMaterial
├── Utils/
│   ├── AppLogger.swift                 # Rotating file logger
│   ├── ExperimentalConfigurationModifier.swift
│   ├── HotkeyManager.swift            # Carbon RegisterEventHotKey (Ctrl+Option+B)
│   ├── FullscreenDetector.swift        # Auto-hide bar on fullscreen apps
│   ├── ImageCache.swift                # Async image caching
│   ├── VersionChecker.swift            # Version tracking for "What's New"
│   └── WindowGapManager.swift          # AX-based window gap enforcement
├── Views/
│   ├── MenuBarView.swift               # Widget registry — routes widget IDs to views
│   ├── BackgroundView.swift            # Bar background
│   ├── OnboardingView.swift            # First-launch welcome (4 pages)
│   └── AppUpdater.swift                # Version-check-only (opens GitHub releases)
└── Widgets/                            # See Widgets table below
```

## Widgets

| Widget ID | Directory | Key API / Notes |
|---|---|---|
| `default.spaces` | `Spaces/` | CGS private API, yabai, AeroSpace. 5 display modes, 4 highlight styles |
| `default.activeapp` | `ActiveApp/` | `NSWorkspace.didActivateApplicationNotification` |
| `default.nowplaying` | `NowPlaying/` | MediaRemote (primary) + AppleScript fallback. Optimistic UI + grace period |
| `default.time` | `Time+Calendar/` | ICU date format, EventKit calendar popup |
| `default.battery` | `Battery/` | IOKit `AppleSmartBattery`, ring popup |
| `default.network` | `Network/` | `getifaddrs` + CoreWLAN, signal/speed/IP popup |
| `default.volume` | `Volume/` | CoreAudio, event-driven, scroll-to-adjust |
| `default.weather` | `Weather/` | MET Norway (default) / OpenMeteo, CoreLocation + IP fallback |
| `default.systemmonitor` | `SystemMonitor/` | `host_statistics` CPU + `vm_statistics64` RAM, 3s poll |
| `default.disk` | `Disk/` | `FileManager` disk stats, 60s poll |
| `default.pomodoro` | `Pomodoro/` | Timer states, local notifications |
| `default.inputlanguage` | `InputLanguage/` | TIS API + DistributedNotificationCenter (zero polling) |
| `default.brightness` | `Brightness/` | CoreDisplay via dlopen, scroll-to-adjust |
| `default.clipboard` | `Clipboard/` | NSPasteboard monitor, 20-entry history |
| `default.bluetooth` | `Bluetooth/` | IOBluetooth + IORegistry AirPods battery. Requires IOBluetooth.framework |
| `script.<name>` | `Script/` | Arbitrary shell command at interval |

## Preset System

11 presets in `PresetRegistry.swift`: `liquid-glass`, `frosted`, `flat-dark`, `minimal`, `neon`, `tokyo-night`, `dracula`, `gruvbox`, `nord`, `catppuccin`, `solarized`.

Rendering styles: `glass` (blur + gradient border), `solid` (flat opaque), `minimal` (no background), `system` (native material).

Resolution: Config preset -> `Preset.defaults` -> `.applying(overrides:)` -> `@Environment(\.appearance)`.

## Bar Formations

4 modes via `[experimental.foreground] formation`:

| Formation | Description |
|---|---|
| `full` | Mono-bar spanning full width |
| `floating` | Single rounded capsule (default) |
| `islands` | Individual widget capsules |
| `pills` | Widgets grouped by spacers into pills |

True center alignment with ZStack when 2 spacers create left|center|right sections.

## App Features

- **Tray icon:** `NSStatusItem` with `eye` icon. Menu: Settings, Check for Updates (Sparkle), Launch at Login, Quit
- **Onboarding:** 4-page welcome on first launch. `UserDefaults` key: `hasSeenOnboarding`
- **Settings:** Singleton NSWindow. Tabs: General (preset/formation pickers, custom preset editor, config export/import, hotkey config), Widgets, Spaces, Time, About
- **Custom presets:** Full visual editor for all appearance settings. Stored as TOML in `~/Library/Application Support/glance/presets/`
- **What's New:** `VersionChecker` detects version change -> `ChangelogPopup` fetches `CHANGELOG.md` from GitHub (falls back to bundled file)
- **Sparkle:** EdDSA-signed updates via `appcast.xml`. SPM dependency (2.9.0)
- **AppUpdater:** Polls GitHub releases every 30min, opens browser (no auto-install)
- **Window gaps:** AX observers push windows below bar. Initial scan + 2s delayed sweep on startup
- **Global hotkey:** Configurable via Settings or TOML `hotkey = "ctrl+option+b"` (Carbon `RegisterEventHotKey`)
- **Fullscreen auto-hide:** Compares frontmost window bounds to screen frame, fades bar

## Known Gotchas

### CGS Private APIs (Spaces)
```swift
@_silgen_name("CGSMainConnectionID") func CGSMainConnectionID() -> Int
@_silgen_name("CGSCopyManagedDisplaySpaces") func CGSCopyManagedDisplaySpaces(_ conn: Int) -> CFArray
@_silgen_name("CGSCopySpacesForWindows") func CGSCopySpacesForWindows(_ conn: Int, _ mask: Int, _ wIDs: CFArray) -> CFArray?
```
- `CGSManagedDisplaySetCurrentSpace` does NOT work on Sequoia — use app activation approach instead
- CGS reports new space before `CGWindowListCopyWindowInfo` updates — verify via `CGSCopySpacesForWindows`
- `cgsAvailable` flag for graceful degradation

### NSImage(named: "AppIcon") Does NOT Work
Use `NSApp.applicationIconImage` instead.

### Xcode Auto-Discovery
`PBXFileSystemSynchronizedRootGroup` compiles ALL `.swift` in `Glance/`. Unfinished files cause build errors. Move them out before building.

### CLAuthorizationStatus on macOS
Uses `.authorized` (not `.authorizedWhenInUse`). `startUpdatingLocation()` triggers the permission prompt. IP fallback via `ipapi.co/json/` when denied.

### macOS Focus/DND — NOT Possible
Third-party apps cannot toggle Focus modes. TCC restricts all APIs. Widget was abandoned.

### Version Bumping
Must update BOTH `Info.plist` (`CFBundleShortVersionString` + `CFBundleVersion`) AND `project.pbxproj` (`MARKETING_VERSION` + `CURRENT_PROJECT_VERSION`).

### AX Permission Revocation
macOS revokes Accessibility after app rebuild (new binary hash). User must re-enable in System Settings.

## Configuration Reference

Config file: `~/.glance-config.toml`

```toml
theme = "dark"
preset = "liquid-glass"

[widgets]
displayed = [
    "default.spaces", "divider", "default.activeapp", "default.nowplaying",
    "spacer",
    "default.weather", "default.systemmonitor", "default.disk",
    "default.volume", "default.network", "default.inputlanguage",
    "default.brightness", "default.clipboard", "default.bluetooth",
    "divider", "default.time",
]

[widgets.default.spaces]
space.display-mode = "icons"    # icons | numbers | dots | icons-only | focused-only
space.highlight = "opacity"     # opacity | pill | underline | glow

[widgets.default.time]
format = "E d MMM, H:mm"

[experimental.foreground]
formation = "floating"          # full | floating | islands | pills
# auto-hide = false

# See source for full config options: battery, volume, brightness, weather, pomodoro, script, etc.
```

## Release Process

1. Bump version in `Info.plist` + `project.pbxproj`
2. Update `CHANGELOG.md`
3. Move style files, build (`./scripts/build-dmg.sh`), restore
4. Sign: `./build/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update release/Glance-X.Y.Z.zip`
5. Update `appcast.xml`, commit, push, tag, GitHub Release, Homebrew cask

## Debugging Tips

- **NSLog/print don't work** in SwiftUI body. Use `AppLogger` or write to `/tmp/glance_debug.log`
- **Deployed app not updating?** Always `rm -rf` before `cp -R`
- **Build fails?** Move style files out first (see Build & Deploy)
- **Weather not showing?** Check `NSLocationUsageDescription` in Info.plist. IP fallback should work if Location denied
- **NowPlaying disappeared?** Check Automation permissions. Grace period (10 nil = ~3s) handles transient failures
- **"What's New" empty?** `CHANGELOG.md` needs `## X.Y.Z` matching `CFBundleShortVersionString`
- **Sparkle no updates?** `appcast.xml` needs `<item>` entries, empty `<channel>` = no versions found
- **Bluetooth empty?** `IOBluetooth.framework` must be linked in Build Phases
- **`sign_update` hangs?** Waiting for Keychain GUI approval

## Security

All network requests use HTTPS. No ATS exceptions in Info.plist.

| Area | Approach |
|---|---|
| **Custom presets** | `CustomPresetStore.safeFileURL()` sanitizes names — strips `/`, `\0`, validates resolved path stays in presetsDir. Prevents path traversal |
| **Script widget** | Runs user-configured shell commands via `/bin/sh -c`. By design — user controls the command in TOML config. Timeout enforced (default 5s) |
| **SpacesCommandRunner** | Uses `Process.executableURL` + `arguments` array. No shell involved — no injection possible |
| **AppleScript** | All scripts hardcoded in `MusicApp` enum. No user input interpolated into AppleScript |
| **Config import** | File selected via native NSOpenPanel. Malformed TOML handled gracefully by decoder |
| **Clipboard history** | In-memory only (`@Published var entries`). Never persisted to disk |
| **Logs** | `~/Library/Application Support/glance/logs/`, 512KB rotation. No credentials or user data logged |
| **Private APIs** | Brightness (dlopen DisplayServices/CoreDisplay), Spaces (CGS) — stability risk only, no security exposure |

When adding new features that accept user input for file paths or shell commands, always sanitize through `lastPathComponent` + path containment check, or use `Process.arguments` (never shell interpolation).

## TODO

**Medium:**
- Multi-monitor support (bar per display)
- Widget SDK / Plugin API

**Long-term:**
- Community presets (shared via GitHub / JSON)
- Localization (Russian, Chinese)
- Notification center widget

