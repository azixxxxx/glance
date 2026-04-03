# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.3.x   | Yes       |
| 1.2.x   | Security fixes only |
| < 1.2   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it privately:

**Email:** azimsukhanov@icloud.com

Please do NOT open a public issue for security vulnerabilities.

I will acknowledge your report within 48 hours and provide a fix timeline.

## Security Considerations

- **Script widget** runs user-configured shell commands — by design, the user controls the command
- **Custom presets** use sanitized file paths (path traversal protection)
- **No network telemetry** — the app only contacts MET Norway / OpenMeteo for weather and GitHub for update checks
- **All network requests use HTTPS** — no ATS exceptions
- **Clipboard history** is in-memory only, never persisted to disk
