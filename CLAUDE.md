# Glance — Custom macOS Status Bar

Modern macOS status bar replacement with liquid glass UI, native Spaces support, and custom widgets. Originally forked from Barik, now a standalone project.

**Version:** 1.0.0
**Author:** azixxxxx (Azim Sukhanov)

## System Context

- **Hardware:** Mac Mini M4, 1080p display
- **Network:** Wi-Fi only (no Ethernet)
- **Window Manager:** Native macOS (no yabai, no AeroSpace)
- **macOS:** Sequoia
- **Theme:** Tokyo Night (dark)
- **Config file:** `~/.glance-config.toml`
- **Deployed at:** `/Applications/Glance.app`
- **Bundle ID:** `com.azimsukhanov.glance`

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
# Output: release/Glance-1.0.0.dmg + release/Glance-1.0.0.zip
```

**Important:** Always `rm -rf` before `cp -R`. Otherwise the old binary may persist even after rebuilding.

## Project Structure

```
Glance/
├── Info.plist                          # LSUIElement=true, v1.0.0
├── AppDelegate.swift                   # App lifecycle, tray icon, login item
├── GlanceApp.swift                     # SwiftUI app entry (@main)
├── Constants.swift                     # App constants
├── Config/
│   ├── ConfigManager.swift             # Config loading, file watching, live reload
│   ├── ConfigModels.swift              # RootToml, Config, style support
│   ├── AppearanceConfig.swift          # Visual params struct + resolvedCornerRadius
│   └── PresetRegistry.swift            # 11 built-in presets (Preset enum)
├── MenuBarPopup/                       # Popup infrastructure (glass background)
├── Resources/                          # Asset catalog (colors, icons)
├── Settings/
│   ├── SettingsWindowController.swift  # NSWindow manager for Settings
│   ├── SettingsView.swift              # Tab-based settings (sidebar nav)
│   └── Tabs/
│       ├── GeneralSettingsTab.swift    # Preset picker, appearance sliders
│       ├── WidgetsSettingsTab.swift    # Widget list config
│       ├── SpacesSettingsTab.swift     # Spaces widget config
│       ├── TimeSettingsTab.swift       # Time format config
│       └── AboutSettingsTab.swift      # Version, credits (Made by azixxxxx)
├── Styles/
│   ├── BarStyleProvider.swift          # Protocol + BarStyle enum + @Environment keys
│   ├── GlassStyle.swift                # Liquid glass — blur + highlight + border
│   ├── SolidStyle.swift                # Flat opaque background
│   ├── MinimalStyle.swift              # Transparent, text/icons only
│   └── SystemStyle.swift               # Native macOS .regularMaterial
├── Utils/
│   ├── ExperimentalConfigurationModifier.swift  # Widget backgrounds (reads appearance)
│   ├── ImageCache.swift                # Async image caching
│   └── VersionChecker.swift            # Version tracking for "What's New"
├── Views/
│   ├── MenuBarView.swift               # Widget registry — routes widget IDs to views
│   ├── BackgroundView.swift            # Bar background
│   ├── OnboardingView.swift            # First-launch welcome (4 pages)
│   ├── OnboardingWindowController.swift # Onboarding window lifecycle
│   └── AppUpdater.swift                # Auto-update from GitHub releases
└── Widgets/
    ├── ActiveApp/
    │   ├── ActiveAppViewModel.swift    # NSWorkspace frontmost app tracking
    │   └── ActiveAppWidget.swift
    ├── Battery/
    │   ├── BatteryManager.swift        # IOKit health, cycles, temp, time remaining
    │   ├── BatteryWidget.swift
    │   └── BatteryPopup.swift          # Ring + health/cycles/temp/power details
    ├── Network/
    │   ├── NetworkWidget.swift         # Wi-Fi + Ethernet icons
    │   ├── NetworkViewModel.swift      # getifaddrs speed, CoreWLAN info, local IP
    │   └── NetworkPopup.swift          # Signal bars, live speed, IP, Tx Rate
    ├── NowPlaying/
    │   ├── NowPlayingManager.swift     # AppleScript bridge (Music + Spotify), album field
    │   ├── NowPlayingWidget.swift
    │   └── NowPlayingPopup.swift       # Album art, progress bar, playback controls
    ├── Spaces/
    │   ├── SpacesModels.swift          # Protocols + type erasure
    │   ├── SpacesViewModel.swift       # Provider selection + IconCache
    │   ├── SpacesWidget.swift
    │   ├── Native/
    │   │   ├── NativeSpacesModels.swift
    │   │   └── NativeSpacesProvider.swift  # CGS private API
    │   ├── Aerospace/
    │   └── Yabai/
    ├── SystemBanner/                   # System banner + changelog
    ├── Time+Calendar/
    │   ├── TimeWidget.swift
    │   ├── CalendarManager.swift
    │   └── CalendarPopup.swift         # Calendar grid + events, luminance-based contrast
    └── Volume/
        ├── VolumeWidget.swift          # Icon + scroll overlay
        ├── VolumeViewModel.swift       # CoreAudio volume + output device name
        └── VolumePopup.swift           # Slider + mute + output device info
```

## Preset System

11 built-in presets in `PresetRegistry.swift`. Each preset defines a full `AppearanceConfig`.

| Preset | Rendering | Description |
|---|---|---|
| `liquid-glass` | glass | Default — blur, bright gradient border, capsule |
| `frosted` | glass | Softer blur, dim border, rounded rect |
| `flat-dark` | solid | 2D, no blur, thin border |
| `minimal` | minimal | Text/icons only, no background |
| `neon` | solid | Bright pink glowing border |
| `tokyo-night` | solid | Tokyo Night color scheme |
| `dracula` | solid | Dracula color scheme |
| `gruvbox` | solid | Gruvbox color scheme |
| `nord` | solid | Nord color scheme |
| `catppuccin` | solid | Catppuccin Mocha color scheme |
| `solarized` | solid | Solarized Dark color scheme |

### Appearance Resolution

```
Config preset → Preset.defaults (AppearanceConfig)
  → .applying(overrides: rootToml.appearanceOverrides)
    → Final AppearanceConfig
      → .environment(\.appearance, ...) in MenuBarView
        → Widgets/popups read @Environment(\.appearance)
```

`AppearanceConfig` fields: renderingStyle, roundness (0-50), borderWidth, borderTopOpacity, borderMidOpacity, borderBottomOpacity, fillOpacity, glowOpacity, glowRadius, shadowOpacity, shadowRadius, shadowY, blurMaterial, popupDarkTint, popupRoundness, foregroundColor, accentColor, borderColor, borderColor2, widgetBackgroundColor, glowColor.

### Legacy Support

`style = "glass"` → maps to `liquid-glass` preset via `Preset.fromLegacyStyle()`.

## Style System

All widget backgrounds and popup backgrounds go through `BarStyleProvider`.

### Rendering Styles (BarStyle enum)

| Style | Description |
|---|---|
| `glass` | ultraThinMaterial + highlight gradient + gradient border + shadow |
| `solid` | Flat opaque fill, no blur |
| `minimal` | No background at all |
| `system` | Native macOS `.regularMaterial` |

### Glass Layers (GlassStyle)

Widget capsules:
1. `.ultraThinMaterial` — base blur
2. Linear gradient overlay (highlight) — configurable opacity
3. Linear gradient overlay (inner shadow) — configurable opacity
4. Gradient stroke (border) — configurable width, top/mid/bottom opacity
5. Drop shadow — configurable opacity, radius, y-offset
6. Outer glow — configurable opacity, radius, color

Popups add a dark tint between blur and highlight for text readability.

## Widgets

### Volume Widget (`Widgets/Volume/`)
- **Widget ID:** `default.volume`
- Speaker icon (SF Symbol) reflecting current volume level
- Scroll wheel adjusts volume (NSView overlay for scroll event capture)
- Click opens popup with slider + mute toggle + output device info
- CoreAudio `AudioToolbox` API for volume get/set/mute
- Output device name via `AudioObjectGetPropertyData` + `Unmanaged<CFString>`
- Polls volume every 0.5s via Timer

### Network Widget (`Widgets/Network/`)
- **Widget ID:** `default.network`
- Wi-Fi + Ethernet status icons with color states
- Popup: signal bars, RSSI, quality, band badge, live upload/download speed, local IP, channel, Tx Rate, noise
- Speed tracking via `getifaddrs` + `if_data` byte counters (2s interval)
- Local IP via `getifaddrs` scanning `en0`/`en1` for `AF_INET`
- Tx Rate via CoreWLAN `transmitRate()`

### Battery Widget (`Widgets/Battery/`)
- **Widget ID:** `default.battery`
- Battery level with charging indicator
- Popup: ring progress + health %, cycle count, temperature, power source, time remaining
- IOKit `AppleSmartBattery` via `IORegistryEntryCreateCFProperties`
- Temperature from `dict["Temperature"]` / 100 (centi-degrees)
- Time remaining via `IOPSGetTimeRemainingEstimate()`

### Now Playing Widget (`Widgets/NowPlaying/`)
- **Widget ID:** `default.nowplaying`
- Current track with album art thumbnail
- Popup: large album art (220x220), title/artist/album, smooth progress bar with knob + glow, playback controls
- AppleScript bridge for Music + Spotify (7 pipe-separated fields: state|title|artist|album|artworkURL|position|duration)

### Active App Widget (`Widgets/ActiveApp/`)
- **Widget ID:** `default.activeapp`
- Frontmost app name with animated transitions
- `NSWorkspace.didActivateApplicationNotification`

### Time Widget (`Widgets/Time+Calendar/`)
- **Widget ID:** `default.time`
- ICU date format patterns via `formatter.dateFormat`
- Calendar popup: month grid, weekday headers, today highlight with luminance-based contrast
- Events list (today + tomorrow) via EventKit

### Spaces Widget (`Widgets/Spaces/`)
- **Widget ID:** `default.spaces`
- Native macOS spaces (CGS private API), yabai, or AeroSpace
- App icons per space, click to switch

## App Features

### Tray Icon (AppDelegate)
- `NSStatusItem` with SF Symbol `eye` (template image)
- Menu: Settings... (Cmd+,), Launch at Login toggle, Quit (Cmd+Q)
- Login item via `SMAppService.mainApp` (macOS 13+)

### Onboarding
- `OnboardingWindowController` shows on first launch
- 4 pages: Welcome, Widgets, Presets, Config
- `UserDefaults` key: `hasSeenOnboarding`
- Uses `NSApp.applicationIconImage` (NOT `NSImage(named: "AppIcon")` — that doesn't work for AppIcon assets)

### Settings GUI
- `SettingsWindowController` — singleton, NSWindow managed manually (LSUIElement app)
- Tabs: General (preset picker, appearance), Widgets, Spaces, Time, About
- About tab: version, "Made by azixxxxx", GitHub link

### Distribution
- `scripts/build-dmg.sh` — builds Release, creates DMG + ZIP in `release/`
- DMG includes Applications symlink for drag-and-drop install

## Known Technical Details

### CGS Private APIs (NativeSpacesProvider)

```swift
@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> Int

@_silgen_name("CGSCopyManagedDisplaySpaces")
private func CGSCopyManagedDisplaySpaces(_ conn: Int) -> CFArray

@_silgen_name("CGSCopySpacesForWindows")
private func CGSCopySpacesForWindows(_ conn: Int, _ mask: Int, _ windowIDs: CFArray) -> CFArray?
```

**What does NOT work on macOS Sequoia:**
- `CGSManagedDisplaySetCurrentSpace` — pulls windows to current space instead of switching
- `CGSShowSpaces` / `CGSHideSpaces` — same problem

**What works:** App activation approach — find a window exclusively on the target space, activate its `NSRunningApplication`. macOS switches spaces automatically.

### Thread Safety (NativeSpacesProvider)

`SpacesViewModel` polls every 100ms on `DispatchQueue.global(.background)`. Multiple calls can overlap. `NativeSpacesProvider.getSpacesWithWindows()` uses `NSLock` to serialize access to `windowCache` dictionary (Swift Dictionary is not thread-safe).

### Race Condition During Space Transitions

CGS reports the new space as "Current Space" before `CGWindowListCopyWindowInfo(.optionOnScreenOnly)` updates. Solution: verify the first on-screen window belongs to the current space via `CGSCopySpacesForWindows` before caching.

### NSImage(named: "AppIcon") Does NOT Work

macOS does not expose the AppIcon asset catalog image via `NSImage(named:)`. Use `NSApp.applicationIconImage` instead for displaying the app icon at runtime.

### CoreAudio CFString Pattern

Reading audio device name requires `Unmanaged<CFString>` pattern to avoid unsafe pointer warnings:
```swift
var name: Unmanaged<CFString>?
withUnsafeMutablePointer(to: &name) { ptr in
    AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
}
if let cfName = name?.takeUnretainedValue() { ... }
```

### Calendar Today Contrast

`CalendarDaysView.todayTextColor` calculates luminance of `accentColor` (0.299R + 0.587G + 0.114B) and returns `.black` if light (>0.6) or `.white` if dark. This ensures the today circle text is always readable regardless of preset.

## Configuration Reference

Config file location: `~/.glance-config.toml`

```toml
theme = "dark"
preset = "liquid-glass"   # See Preset System above

# Override individual appearance values:
# [appearance]
# roundness = 50
# border-width = 1.0
# foreground-color = "#ffffff"
# accent-color = "#7aa2f7"

[widgets]
displayed = [
    "default.spaces",
    "divider",
    "default.activeapp",
    "default.nowplaying",
    "spacer",
    "default.volume",
    "default.network",
    "divider",
    "default.time",
]

[widgets.default.spaces]
space.show-key = true
window.show-title = true
window.title.max-length = 50

[widgets.default.battery]
show-percentage = true
warning-level = 30
critical-level = 10

[widgets.default.time]
format = "E d MMM, H:mm"
calendar.format = "H:mm"
calendar.show-events = true

[popup.default.time]
view-variant = "box"

[background]
enabled = true

[experimental.foreground]
height = "default"
horizontal-padding = 20
spacing = 12

[experimental.foreground.widgets-background]
displayed = true
blur = 5

[experimental.background]
displayed = true
height = "default"
blur = 4
```

## TODO: Next Version (v1.0.1+)

### Sparkle Auto-Updates (priority)
- Add Sparkle via SPM: `https://github.com/sparkle-project/Sparkle`
- Does NOT require Apple Developer account — use Sparkle's own EdDSA signing
- Steps: generate EdDSA key (`generate_keys`), create appcast.xml, host on GitHub Pages or in repo
- Add "Check for Updates" to tray menu
- Sign builds with `sign_update` tool from Sparkle before publishing

### Graceful Degradation for CGS APIs
- All CGS calls are isolated in `NativeSpacesProvider.swift`
- No public Apple API exists for Spaces — CGS is industry standard (SketchyBar, yabai, AeroSpace all use it)
- CGS API has been stable since macOS Catalina — low risk but not zero
- TODO: wrap CGS calls in error handling so widget shows "Spaces unavailable" instead of crashing if API breaks
- `CGWindowListCopyWindowInfo` (public API) is already used for windows — won't break

### Other Planned Features
- Homebrew cask submission (after 30+ stars)
- Keyboard shortcut for show/hide bar (global hotkey)
- Drag & drop widget reordering in Settings GUI
- Custom script widgets (shell/python output as widget)
- Weather widget (WeatherKit or OpenMeteo API)
- CPU/RAM monitor widget
- Multi-monitor support
- Localization (Russian, Chinese)

## Debugging Tips

- **NSLog/print don't work** from SwiftUI body. Use file-based logging:
  ```swift
  try? "message\n".write(toFile: "/tmp/glance_debug.log", atomically: true, encoding: .utf8)
  ```
- **Deployed app not updating?** Always `rm -rf /Applications/Glance.app` before `cp -R`.
- **Windows appearing on wrong space?** Check `CGSCopySpacesForWindows` verification in `getSpacesWithWindows()`.
- **BetterDisplay or virtual displays** can create extra entries in `CGSCopyManagedDisplaySpaces`. The code uses `displaySpaces.first` (main display only).
- **Crash on boot (data race)?** `NativeSpacesProvider` uses `NSLock` to prevent concurrent Dictionary mutation.
- **Icon not showing?** Use `NSApp.applicationIconImage`, not `NSImage(named: "AppIcon")`.
- **Onboarding not showing?** Check `defaults read com.azimsukhanov.glance hasSeenOnboarding`. Reset with `defaults delete`.
