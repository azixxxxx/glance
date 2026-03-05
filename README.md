# Glance

Modern macOS status bar replacement with liquid glass UI, native Spaces support, and configurable widgets.

## Features

- **Liquid Glass design** — blur, gradient borders, glow, and shadows for a premium glass look
- **Native macOS Spaces** — works out of the box, no yabai or AeroSpace required
- **Configurable presets** — switch between `liquid-glass`, `frosted`, `flat-dark`, `minimal-strip`, `system-native`, `neon` with one line
- **Live reload** — edit `~/.glance-config.toml`, changes apply instantly
- **Lightweight** — native Swift/SwiftUI, no Electron

## Widgets

| Widget | Description |
|--------|-------------|
| **Spaces** | Workspace indicators with app icons, click to switch |
| **Active App** | Frontmost application name |
| **Now Playing** | Current track with album art |
| **Volume** | Speaker icon, scroll to adjust, click for slider |
| **Network** | Wi-Fi and Ethernet status |
| **Battery** | Battery level with charging indicator |
| **Time** | Customizable date/time with calendar popup |

## Installation

### Build from source

Requires Xcode 16+ and macOS 14.6+.

```bash
git clone https://github.com/azimsukhanov/glance.git
cd glance

xcodebuild -project Glance.xcodeproj -scheme Glance -configuration Release \
  -derivedDataPath build build \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

cp -R build/Build/Products/Release/Glance.app /Applications/
open /Applications/Glance.app
```

## Configuration

Config file: `~/.glance-config.toml`

A default config is created on first launch. Example:

```toml
theme = "dark"

# Visual preset (one line changes everything)
preset = "liquid-glass"

# Fine-tune appearance (overrides preset values)
# [appearance]
# roundness = 50       # 0 = square, 50 = capsule
# border-width = 1.0
# border-opacity = 0.4
# fill-opacity = 0.04
# glow-opacity = 0.05
# shadow-opacity = 0.08
# shadow-radius = 4.0

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

[widgets.default.time]
format = "E d MMM, H:mm"
calendar.format = "H:mm"
calendar.show-events = true

[popup.default.time]
view-variant = "box"

[background]
enabled = true
```

### Presets

| Preset | Style | Description |
|--------|-------|-------------|
| `liquid-glass` | Glass | Blur, bright border, capsule shape (default) |
| `frosted` | Glass | Softer — dim border, rounded rectangle |
| `flat-dark` | Solid | 2D, no blur, thin border |
| `minimal-strip` | Minimal | Text only, no background |
| `system-native` | System | Native macOS material |
| `neon` | Solid | Bright glowing border |

### Legacy support

The old `style = "glass"` syntax still works and maps to the `liquid-glass` preset.

### Date format patterns

Uses ICU date format with `dateFormat`:

| Pattern | Output |
|---------|--------|
| `E d MMM, H:mm` | Wed 5 Mar, 17:14 |
| `H:mm` | 17:14 |
| `h:mm a` | 5:14 PM |
| `EEEE, d MMMM yyyy` | Wednesday, 5 March 2026 |

## Requirements

- macOS 14.6 (Sonoma) or later
- Apple Silicon or Intel Mac

## License

MIT
