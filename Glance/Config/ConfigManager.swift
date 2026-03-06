import Foundation
import SwiftUI
import TOMLDecoder

final class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    @Published private(set) var config = Config()
    @Published private(set) var initError: String?
    
    private var fileWatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
    private var configFilePath: String?

    private init() {
        loadOrCreateConfigIfNeeded()
    }

    private func loadOrCreateConfigIfNeeded() {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        let path1 = "\(homePath)/.glance-config.toml"
        let path2 = "\(homePath)/.config/glance/config.toml"
        var chosenPath: String?

        if FileManager.default.fileExists(atPath: path1) {
            chosenPath = path1
        } else if FileManager.default.fileExists(atPath: path2) {
            chosenPath = path2
        } else {
            do {
                try createDefaultConfig(at: path1)
                chosenPath = path1
            } catch {
                initError = "Error creating default config: \(error.localizedDescription)"
                print("Error when creating default config:", error)
                return
            }
        }

        if let path = chosenPath {
            configFilePath = path
            parseConfigFile(at: path)
            startWatchingFile(at: path)
        }
    }

    private func parseConfigFile(at path: String) {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let decoder = TOMLDecoder()
            let rootToml = try decoder.decode(RootToml.self, from: content)
            DispatchQueue.main.async {
                self.config = Config(rootToml: rootToml)
            }
        } catch {
            initError = "Error parsing TOML file: \(error.localizedDescription)"
            print("Error when parsing TOML file:", error)
        }
    }

    private func createDefaultConfig(at path: String) throws {
        let defaultTOML = """
            # If you installed yabai or aerospace without using Homebrew,
            # manually set the path to the binary. For example:
            #
            # yabai.path = "/run/current-system/sw/bin/yabai"
            # aerospace.path = ...

            theme = "system" # system, light, dark

            # Visual preset (overrides style). Available:
            #   liquid-glass, frosted, flat-dark, minimal-strip, system-native, neon
            # preset = "liquid-glass"

            # Override individual appearance parameters (optional):
            # [appearance]
            # roundness = 50       # 0 = square, 50 = capsule
            # border-width = 1.0
            # border-opacity = 0.4
            # fill-opacity = 0.04
            # glow-opacity = 0.05
            # shadow-opacity = 0.08
            # shadow-radius = 4.0

            [widgets]
            displayed = [ # widgets on menu bar
                "default.spaces",
                "spacer",
                "default.network",
                "default.battery",
                "divider",
                # { "default.time" = { time-zone = "America/Los_Angeles", format = "E d, hh:mm" } },
                "default.time"
            ]

            [widgets.default.spaces]
            space.show-key = true        # show space number (or character, if you use AeroSpace)
            window.show-title = true
            window.title.max-length = 50

            [widgets.default.battery]
            show-percentage = true
            warning-level = 30
            critical-level = 10

            [widgets.default.time]
            format = "E d, J:mm"
            calendar.format = "J:mm"

            calendar.show-events = true
            # calendar.allow-list = ["Home", "Personal"] # show only these calendars
            # calendar.deny-list = ["Work", "Boss"] # show all calendars except these

            [popup.default.time]
            view-variant = "box"
            
            [background]
            enabled = true
            """
        try defaultTOML.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func startWatchingFile(at path: String) {
        fileDescriptor = open(path, O_EVTONLY)
        if fileDescriptor == -1 { return }
        fileWatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor, eventMask: .write,
            queue: DispatchQueue.global())
        fileWatchSource?.setEventHandler { [weak self] in
            guard let self = self, let path = self.configFilePath else {
                return
            }
            self.parseConfigFile(at: path)
        }
        fileWatchSource?.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd != -1 {
                close(fd)
            }
        }
        fileWatchSource?.resume()
    }

    func updateConfigValue(key: String, newValue: String) {
        guard let path = configFilePath else {
            print("Config file path is not set")
            return
        }
        do {
            let currentText = try String(contentsOfFile: path, encoding: .utf8)
            let updatedText = updatedTOMLString(
                original: currentText, key: key, newValue: newValue)
            try updatedText.write(
                toFile: path, atomically: false, encoding: .utf8)
            // File watcher will trigger parseConfigFile automatically
        } catch {
            print("Error updating config:", error)
        }
    }

    /// Batch-update multiple config keys in a single file write.
    func updateConfigValues(pairs: [(key: String, value: String)]) {
        guard let path = configFilePath else {
            print("Config file path is not set")
            return
        }
        do {
            var text = try String(contentsOfFile: path, encoding: .utf8)
            for (key, value) in pairs {
                text = updatedTOMLString(original: text, key: key, newValue: value)
            }
            try text.write(toFile: path, atomically: false, encoding: .utf8)
        } catch {
            print("Error batch-updating config:", error)
        }
    }

    /// Formats a value for TOML: numbers and booleans are bare, arrays are bare, strings get quotes.
    private func tomlFormatted(_ value: String) -> String {
        // Booleans
        if value == "true" || value == "false" { return value }
        // Arrays
        if value.hasPrefix("[") && value.hasSuffix("]") { return value }
        // Integer
        if Int(value) != nil { return value }
        // Float
        if Double(value) != nil { return value }
        // String — wrap in quotes
        return "\"\(value)\""
    }

    /// Count unbalanced open brackets in a string (for multi-line array detection).
    private func unclosedBracketDepth(_ s: String) -> Int {
        var depth = 0
        for ch in s {
            if ch == "[" { depth += 1 }
            else if ch == "]" { depth -= 1 }
        }
        return depth
    }

    private func updatedTOMLString(
        original: String, key: String, newValue: String
    ) -> String {
        let formatted = tomlFormatted(newValue)

        if key.contains(".") {
            let components = key.split(separator: ".").map(String.init)
            guard components.count >= 2 else {
                return original
            }

            let tablePath = components.dropLast().joined(separator: ".")
            let actualKey = components.last!

            let tableHeader = "[\(tablePath)]"
            let lines = original.components(separatedBy: "\n")
            var newLines: [String] = []
            var insideTargetTable = false
            var updatedKey = false
            var foundTable = false
            var skipBracketDepth = 0

            for line in lines {
                // Skip continuation lines of a replaced multi-line value
                if skipBracketDepth > 0 {
                    skipBracketDepth += unclosedBracketDepth(line)
                    continue
                }

                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("[") && !trimmed.hasPrefix("[[") && trimmed.hasSuffix("]") && !trimmed.hasSuffix("]]") {
                    if insideTargetTable && !updatedKey {
                        newLines.append("\(actualKey) = \(formatted)")
                        updatedKey = true
                    }
                    if trimmed == tableHeader {
                        foundTable = true
                        insideTargetTable = true
                    } else {
                        insideTargetTable = false
                    }
                    newLines.append(line)
                } else {
                    if insideTargetTable && !updatedKey {
                        let pattern =
                            "^\(NSRegularExpression.escapedPattern(for: actualKey))\\s*="
                        if line.range(of: pattern, options: .regularExpression)
                            != nil
                        {
                            newLines.append("\(actualKey) = \(formatted)")
                            updatedKey = true
                            // Check if original line had unclosed brackets (multi-line value)
                            let depth = unclosedBracketDepth(line)
                            if depth > 0 { skipBracketDepth = depth }
                            continue
                        }
                    }
                    newLines.append(line)
                }
            }

            if foundTable && insideTargetTable && !updatedKey {
                newLines.append("\(actualKey) = \(formatted)")
            }

            if !foundTable {
                newLines.append("")
                newLines.append("[\(tablePath)]")
                newLines.append("\(actualKey) = \(formatted)")
            }
            return newLines.joined(separator: "\n")
        } else {
            let lines = original.components(separatedBy: "\n")
            var newLines: [String] = []
            var updatedAtLeastOnce = false
            var skipBracketDepth = 0

            for line in lines {
                // Skip continuation lines of a replaced multi-line value
                if skipBracketDepth > 0 {
                    skipBracketDepth += unclosedBracketDepth(line)
                    continue
                }

                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if !trimmed.hasPrefix("#") {
                    let pattern =
                        "^\(NSRegularExpression.escapedPattern(for: key))\\s*="
                    if line.range(of: pattern, options: .regularExpression)
                        != nil
                    {
                        newLines.append("\(key) = \(formatted)")
                        updatedAtLeastOnce = true
                        let depth = unclosedBracketDepth(line)
                        if depth > 0 { skipBracketDepth = depth }
                        continue
                    }
                }
                newLines.append(line)
            }
            if !updatedAtLeastOnce {
                // Insert before the first [section] header so the key stays top-level
                var inserted = false
                var result: [String] = []
                for line in newLines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if !inserted && trimmed.hasPrefix("[") && !trimmed.hasPrefix("[[") && trimmed.hasSuffix("]") && !trimmed.hasSuffix("]]") {
                        result.append("\(key) = \(formatted)")
                        result.append("")
                        inserted = true
                    }
                    result.append(line)
                }
                if !inserted {
                    result.append("\(key) = \(formatted)")
                }
                return result.joined(separator: "\n")
            }
            return newLines.joined(separator: "\n")
        }
    }

    func globalWidgetConfig(for widgetId: String) -> ConfigData {
        config.rootToml.widgets.config(for: widgetId) ?? [:]
    }

    func resolvedWidgetConfig(for item: TomlWidgetItem) -> ConfigData {
        let global = globalWidgetConfig(for: item.id)
        if item.inlineParams.isEmpty {
            return global
        }
        var merged = global
        for (key, value) in item.inlineParams {
            merged[key] = value
        }
        return merged
    }
}
