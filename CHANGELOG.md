# Changelog

## 1.3.1

### Bug Fixes
- Fixed config corruption when changing calendar settings via Settings UI — dotted keys under `[widgets.default.time]` (e.g. `calendar.show-events`) were duplicated as a separate `[widgets.default.time.calendar]` section, causing TOML parsing errors on next launch

## 1.3.0 — "The Bar That Feels Alive"

### Micro-Animations
- Battery bolt icon pulses when charging
- System Monitor glows orange when CPU exceeds 80%
- Pomodoro icon and text pulse red in the last 60 seconds of a work session
- Volume/Brightness show a transient percentage capsule when scroll-adjusting
- Spaces highlight (pill/underline) slides smoothly between spaces via matchedGeometryEffect

### Haptic Feedback
- Scroll-to-adjust volume/brightness triggers a light haptic tick
- Switching spaces triggers a tactile tock
- Quick action buttons trigger haptic feedback
- Configurable via `[feedback] haptics = true/false` in TOML

### Notification Badges
- Battery: yellow/red dot when level drops below warning threshold (not plugged in)
- System Monitor: red dot when CPU exceeds 90%
- Network: yellow dot when Wi-Fi signal is weak
- Badges appear/disappear with spring animation

### Quick Actions (Long-Press)
- Volume: long-press to Mute/Unmute
- Now Playing: long-press for Prev / Play-Pause / Next controls
- Brightness: long-press for 25% / 50% / 75% / 100% preset levels

### Contextual Profiles
- Create named profiles with preset + formation overrides
- Auto-activate by frontmost app (e.g. Xcode → Minimal) or time range (e.g. 18:00-06:00 → Tokyo Night)
- App triggers take priority over time triggers
- Smooth crossfade between profiles
- Full Settings UI for profile management (create, edit, delete)
- Profiles stored in UserDefaults with JSON persistence

### Preset Sharing
- Export current visual preset as a `.glance` file (includes preset, formation, and all appearance overrides)
- Import `.glance` files to instantly apply someone else's style
- Copy a `glance://preset/<base64>` share link to clipboard
- URL scheme and file association registered — double-click `.glance` files or click links to import
- Share Preset section added to Settings > General

## 1.2.1

### Fixes
- Fixed crash in Battery widget when `maxCapacity` is reported as zero (division by zero)
- Fixed crash in Network widget when `ifa_addr` is NULL — affects `getNetworkBytes()` and `updateLocalIP()`
- Fixed TOML config parsing: `[widgets]` section is now optional (configs without it no longer crash)
- Fixed unhelpful "can't be read because it isn't in the correct format" error — parsing errors now show exact key path and reason
- Removed dead config sections (`[popup.default.time]`, `[background]`) from default config template, replaced with documented `[experimental.foreground]` example

## 1.2

### New Widgets
- **Disk** — storage usage with free/total display and usage bar
- **Brightness** — display brightness with scroll-to-adjust (DisplayServices, CoreDisplay, IOKit backends)
- **Bluetooth** — connected devices with battery levels (AirPods, keyboards, mice)
- **Clipboard** — clipboard history with 20-entry buffer, click to paste
- **Input Language** — current keyboard layout, zero-polling via TIS API
- **Pomodoro** — focus timer with work/break cycles, session tracking, and notifications

### New Features
- **4 bar formations**: full, floating, islands, pills — configurable layout modes
- **Global hotkey** (Ctrl+Option+B) to toggle bar visibility, configurable in Settings
- **Fullscreen auto-hide** — bar fades when apps go fullscreen
- **Settings GUI** — full widget management with drag-and-drop reordering, add/remove
- **Preset picker** with live preview diagrams for formations, display modes, and highlight styles
- **Custom preset editor** — create your own presets with full control over colors, shapes, borders, glow, shadows
- **Config Export/Import** — backup and restore your configuration from Settings
- **Changelog fallback** — "What's New" popup works offline using bundled changelog

### Improvements
- Pomodoro timer uses absolute end dates instead of decrement counting — immune to timer drift
- Settings widget list uses stable UUID identity for smooth drag-and-drop
- Fixed feedback loop in Settings that required double-click for add/remove operations
- Config changes are now reactive in Pomodoro widget (live reload without restart)

### Fixes
- Fixed memory leak in Brightness widget (IORegistryEntryCreateCFProperty called twice)
- Fixed data race in Now Playing manager (compiledScripts accessed without synchronization)
- Fixed Bluetooth device ID instability (UUID fallback replaced with name-based fallback)
- Fixed CalendarManager allow/deny list filtering (`.drop(while:)` → `.compactMap + .filter`)
- Fixed main thread blocking in Spaces widget (`usleep` replaced with `asyncAfter`)
- Fixed TimeWidget creating a new DateFormatter every second (now cached)
- Fixed wrong type reference in ConfigModels error message
- Removed dead code: unused ForegroundPadding enum, abandoned Focus widget

### Performance
- AppLogger uses persistent FileHandle instead of open/close per log line
- Timer tolerances added across all widget timers for power efficiency
- Pomodoro timer runs in `.common` RunLoop mode (ticks during UI interactions)

## 1.1.2

### Performance
- Reduced idle CPU usage from ~20% to under 1% (without music playing) and ~2.6% average (with Spotify)
- **Spaces widget**: polling reduced from 100ms to 1s with event-driven refresh on app switch/launch/terminate; cached app name lookups instead of rebuilding every poll
- **Now Playing widget**: adaptive polling (3s playing, 5s paused/idle) instead of constant 300ms; compiled AppleScript caching eliminates repeated script compilation; skips AppleScript entirely when no music app is running
- **Volume widget**: replaced 500ms polling timer with zero-cost CoreAudio property listeners (event-driven)
- **Battery widget**: polling reduced from 1s to 30s; removed redundant recursive scheduling
- **Calendar**: polling reduced from 5s to 60s
- **Network**: WiFi info polling reduced from 5s to 10s; speed monitoring from 2s to 3s
- **System Monitor**: polling reduced from 2s to 3s
- **Menu bar panel**: constrained from full-screen to bar-height only, reducing SwiftUI layout area by ~20x
- All view models now diff-check data before publishing to avoid unnecessary SwiftUI re-renders

## 1.1.1

### Fixes
- Fixed Now Playing widget disappearing from the bar after temporary AppleScript failures (e.g. after Mac sleep or Spotify restart)
- Fixed "What's New" popup showing empty content after updates

## 1.1.0

### New Widgets
- **Weather** — current temperature, conditions, and 5-day forecast via OpenMeteo API with automatic location detection
- **System Monitor** — live CPU and RAM usage with color-coded thresholds
- **Script** — run any shell command and display its output in the bar

### New Features
- Sparkle auto-updates — the app now checks for updates automatically and shows an "Update" button in the bar
- Homebrew Cask support — `brew install --cask glance` via `azixxxxx/tap`
- "What's New" banner after updates with changelog popup

## 1.0.0

### Initial Release
- Custom macOS status bar replacement with liquid glass UI
- Native Spaces support with app icons per space (CGS private API)
- Now Playing widget with album art, progress bar, and playback controls (Spotify & Apple Music)
- Network widget with Wi-Fi signal, speed, and connection details
- Battery widget with health, cycle count, and temperature
- Volume widget with scroll-to-adjust and output device info
- Active App widget showing frontmost application
- Time & Calendar widget with month grid and events
- 11 built-in presets (Liquid Glass, Frosted, Tokyo Night, Dracula, and more)
- Live config reload from `~/.glance-config.toml`
- Window gap management via Accessibility API
- Onboarding flow for first launch
