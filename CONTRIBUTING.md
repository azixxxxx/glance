# Contributing to Glance

Thanks for your interest in contributing!

## Getting Started

1. Fork the repo and clone it
2. Build the project:
   ```bash
   # Move style files (Xcode auto-discovers all .swift)
   mkdir -p /tmp/glance-styles-backup
   mv Glance/Styles/{Glass,Minimal,Solid,System}Style.swift /tmp/glance-styles-backup/

   xcodebuild -project Glance.xcodeproj -scheme Glance -configuration Release \
     -derivedDataPath build build \
     CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

   # Restore style files
   cp /tmp/glance-styles-backup/*.swift Glance/Styles/
   ```
3. Deploy to test:
   ```bash
   pkill -x Glance; sleep 2
   rm -rf /Applications/Glance.app
   cp -R build/Build/Products/Release/Glance.app /Applications/Glance.app
   open /Applications/Glance.app
   ```

## What to Contribute

- **Bug fixes** — check [Issues](https://github.com/azixxxxx/glance/issues)
- **New presets** — add a case to `PresetRegistry.swift`
- **Widget improvements** — each widget is self-contained in `Glance/Widgets/`
- **Translations** — localization support is planned

## Guidelines

- Keep PRs focused — one feature or fix per PR
- Follow existing code patterns (naming, structure, style)
- Test on macOS 14.6+ before submitting
- No Electron, no web views — native Swift/SwiftUI only

## Code Structure

```
Glance/
├── Config/          # TOML config parsing, presets, appearance
├── Settings/        # Settings GUI tabs
├── Widgets/         # One folder per widget
├── Styles/          # Bar rendering styles (glass, solid, minimal)
├── Views/           # Main bar view, badge modifier, quick actions
├── Profiles/        # Contextual profile system
└── Utils/           # Logger, hotkey, feedback, preset sharing
```

## Questions?

Open a [Discussion](https://github.com/azixxxxx/glance/discussions) or file an issue.
