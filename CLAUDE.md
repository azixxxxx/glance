# Glance — Custom macOS Status Bar

Modern macOS status bar replacement with liquid glass UI, native Spaces support, and custom widgets. Originally forked from Barik, now a standalone project.

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
```

**Important:** Always `rm -rf` before `cp -R`. Otherwise the old binary may persist even after rebuilding.

## Project Structure

```
Glance/
├── Info.plist                          # LSUIElement=true (hides Dock icon)
├── AppDelegate.swift                   # App lifecycle
├── GlanceApp.swift                     # SwiftUI app entry (@main)
├── Constants.swift                     # App constants
├── Config/                             # TOML config parsing
│   ├── ConfigManager.swift             # Config loading, file watching, live reload
│   └── ConfigModels.swift              # RootToml, Config, style support
├── MenuBarPopup/                       # Popup infrastructure (glass background)
├── Resources/                          # Asset catalog (colors, icons)
├── Styles/                             # Bar style system
│   ├── BarStyleProvider.swift          # Protocol + BarStyle enum + @Environment key
│   ├── GlassStyle.swift                # Liquid glass (default) — blur + highlight + border
│   ├── SolidStyle.swift                # Flat opaque background
│   ├── MinimalStyle.swift              # Transparent, text/icons only
│   └── SystemStyle.swift               # Native macOS .regularMaterial
├── Utils/
│   ├── ExperimentalConfigurationModifier.swift  # Widget capsule backgrounds (uses style system)
│   └── VersionChecker.swift
├── Views/
│   ├── MenuBarView.swift               # Widget registry — routes widget IDs to views
│   ├── BackgroundView.swift            # Bar background
│   └── AppUpdater.swift                # Auto-update from GitHub releases
└── Widgets/
    ├── ActiveApp/                      # Active app name display
    │   ├── ActiveAppViewModel.swift
    │   └── ActiveAppWidget.swift
    ├── Battery/                        # Battery widget
    ├── Network/                        # Wi-Fi/Ethernet status
    │   ├── NetworkWidget.swift
    │   ├── NetworkViewModel.swift
    │   └── NetworkPopup.swift
    ├── NowPlaying/                     # Now playing widget
    ├── Spaces/                         # Workspaces display
    │   ├── SpacesModels.swift          # Protocols + type erasure
    │   ├── SpacesViewModel.swift       # Provider selection + IconCache
    │   ├── SpacesWidget.swift          # Space + window views
    │   ├── Native/                     # Native macOS spaces (CGS private API)
    │   │   ├── NativeSpacesModels.swift
    │   │   └── NativeSpacesProvider.swift
    │   ├── Aerospace/                  # AeroSpace provider
    │   └── Yabai/                      # Yabai provider
    ├── SystemBanner/                   # System banner + changelog
    ├── Time+Calendar/                  # Time display + calendar popup
    │   ├── TimeWidget.swift
    │   ├── CalendarManager.swift
    │   └── CalendarPopup.swift
    └── Volume/                         # Volume control
        ├── VolumeWidget.swift          # Icon + scroll overlay
        ├── VolumeViewModel.swift       # CoreAudio volume control
        └── VolumePopup.swift           # Slider popup
```

## Style System

Glance uses a pluggable style system for visual theming. All widget backgrounds and popup backgrounds go through `BarStyleProvider`.

### Available Styles

| Style | Config value | Description |
|---|---|---|
| **Glass** (default) | `style = "glass"` | Liquid glass — ultraThinMaterial + highlight gradient + inner shadow + gradient border |
| **Solid** | `style = "solid"` | Flat opaque background, no blur |
| **Minimal** | `style = "minimal"` | No background, text/icons float over desktop |
| **System** | `style = "system"` | Native macOS `.regularMaterial` |

### Architecture

```
Config (style = "glass")
  → ConfigManager.config.barStyle → BarStyle.glass
    → .environment(\.barStyle, ...) in MenuBarView
      → ExperimentalConfigurationModifier reads @Environment(\.barStyle)
        → barStyle.provider.widgetBackground(cornerRadius:)
      → MenuBarPopupView reads @Environment(\.barStyle)
        → barStyle.provider.popupBackground(cornerRadius:)
```

### Glass Layers (GlassStyle)

Widget capsules:
1. `.ultraThinMaterial` — base blur
2. Linear gradient overlay (white 12% top → transparent) — highlight
3. Linear gradient overlay (transparent → black 8% bottom) — inner shadow
4. Gradient stroke (white 25% top → 8% bottom, 0.5pt) — glass border
5. Drop shadow (black 15%, radius 8, y 4)

Popups add a dark tint (black 35%) between blur and highlight for text readability.

## Widgets

### Volume Widget (`Widgets/Volume/`)
- **Widget ID:** `default.volume`
- Speaker icon (SF Symbol) reflecting current volume level
- Scroll wheel adjusts volume (NSView overlay for scroll event capture)
- Click opens popup with slider + mute toggle
- CoreAudio `AudioToolbox` API for volume get/set/mute
- Polls volume every 0.5s via Timer

### Active App Widget (`Widgets/ActiveApp/`)
- **Widget ID:** `default.activeapp`
- Shows frontmost app name (text only)
- `NSWorkspace.didActivateApplicationNotification` for instant updates
- Animated transitions on app change

### Native Spaces Provider (`Widgets/Spaces/Native/`)
- **Widget ID:** Uses existing `default.spaces`
- Auto-selected when neither yabai nor AeroSpace is running
- Private CoreGraphics APIs via `@_silgen_name`
- **Space switching:** Finds window exclusively on target space, activates its NSRunningApplication
- **Thread safety:** `NSLock` serializes `getSpacesWithWindows()` (called from concurrent GCD threads every 100ms)
- **Cache-based window tracking** with race condition protection

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
- Ctrl+number shortcuts — not available in Mission Control

**What works:** App activation approach — find a window exclusively on the target space, activate its `NSRunningApplication`. macOS switches spaces automatically.

### Thread Safety (NativeSpacesProvider)

`SpacesViewModel` polls every 100ms on `DispatchQueue.global(.background)`. Multiple calls can overlap. `NativeSpacesProvider.getSpacesWithWindows()` uses `NSLock` to serialize access to `windowCache` dictionary (Swift Dictionary is not thread-safe).

### Race Condition During Space Transitions

CGS reports the new space as "Current Space" before `CGWindowListCopyWindowInfo(.optionOnScreenOnly)` updates. Solution: verify the first on-screen window belongs to the current space via `CGSCopySpacesForWindows` before caching.

### DateFormat Patterns

Config uses ICU date format patterns with `formatter.dateFormat` (NOT template mode):

| Pattern | Output Example |
|---|---|
| `E d MMM, H:mm` | `Wed 5 Mar, 17:14` |
| `H:mm` | `17:14` |
| `h:mm a` | `5:14 PM` |
| `EEEE, d MMMM yyyy` | `Wednesday, 5 March 2026` |

## Configuration Reference

Config file location: `~/.glance-config.toml`

```toml
theme = "dark"
style = "glass"    # glass | solid | minimal | system

[widgets]
displayed = [
    "default.spaces",      # Workspace indicators with app icons
    "divider",             # Vertical separator line
    "default.activeapp",   # Active app name (text)
    "default.nowplaying",  # Now playing track info
    "spacer",              # Flexible spacer
    "default.volume",      # Volume icon with scroll control
    "default.network",     # Wi-Fi/Ethernet status
    "divider",
    "default.time",        # Date/time with calendar popup
]

[widgets.default.spaces.window]
show-title = false

[widgets.default.time]
format = "E d MMM, H:mm"
calendar.format = "H:mm"
calendar.show-events = true

[popup.default.time]
view-variant = "box"

[background]
enabled = true

[experimental.background]
displayed = true
height = "default"
blur = 4

[experimental.foreground]
height = "default"
horizontal-padding = 20
spacing = 12

[experimental.foreground.widgets-background]
displayed = true
blur = 5

[widgets.default.time.popup]
view-variant = "box"
```

## Debugging Tips

- **NSLog/print don't work** from SwiftUI body. Use file-based logging:
  ```swift
  let log = "/tmp/glance_debug.log"
  try? "message\n".write(toFile: log, atomically: true, encoding: .utf8)
  ```
- **Deployed app not updating?** Always `rm -rf /Applications/Glance.app` before `cp -R`. Check file timestamps with `stat`.
- **Windows appearing on wrong space?** Check `CGSCopySpacesForWindows` verification in `getSpacesWithWindows()`.
- **BetterDisplay or virtual displays** can create extra entries in `CGSCopyManagedDisplaySpaces`. The code uses `displaySpaces.first` (main display only).
- **Crash on boot (data race)?** `NativeSpacesProvider` uses `NSLock` to prevent concurrent Dictionary mutation. If crash recurs, verify lock is intact.

# currentDate
Today's date is 2026-03-05.
