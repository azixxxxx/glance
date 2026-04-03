import SwiftUI

struct ProfilesSettingsTab: View {
    @ObservedObject private var profileManager = ProfileManager.shared

    @State private var showEditor = false
    @State private var editingProfile: Profile?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: - Header description
                SettingsSection(title: "Profiles") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Contextual profiles automatically switch the bar's preset and formation based on the frontmost app or time of day.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("App triggers take priority over time triggers. When no profile matches, the default config is used.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // MARK: - Active Profile
                if let active = profileManager.activeProfile {
                    SettingsSection(title: "Active Profile") {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text(active.name)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(triggerSummary(active.trigger))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Profile List
                SettingsSection(title: "My Profiles") {
                    if profileManager.profiles.isEmpty {
                        Text("No profiles yet. Add one to get started.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(profileManager.profiles) { profile in
                                ProfileRow(
                                    profile: profile,
                                    isActive: profileManager.activeProfile?.id == profile.id
                                ) {
                                    editingProfile = profile
                                    showEditor = true
                                } onDelete: {
                                    profileManager.delete(profile)
                                }
                            }
                        }
                    }

                    Button {
                        editingProfile = nil
                        showEditor = true
                    } label: {
                        Label("Add Profile", systemImage: "plus.circle")
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding(24)
        }
        .sheet(isPresented: $showEditor) {
            ProfileEditorSheet(
                existing: editingProfile,
                onSave: { profile in
                    if editingProfile != nil {
                        profileManager.update(profile)
                    } else {
                        profileManager.add(profile)
                    }
                    showEditor = false
                },
                onCancel: {
                    showEditor = false
                }
            )
        }
    }

    // MARK: - Helpers

    private func triggerSummary(_ trigger: ProfileTrigger) -> String {
        var parts: [String] = []
        if let apps = trigger.apps, !apps.isEmpty {
            parts.append("Apps: \(apps.joined(separator: ", "))")
        }
        if let time = trigger.timeRange, !time.isEmpty {
            parts.append("Time: \(time)")
        }
        return parts.isEmpty ? "No trigger" : parts.joined(separator: " · ")
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Active indicator
            Circle()
                .fill(isActive ? Color.green : Color.white.opacity(0.15))
                .frame(width: 8, height: 8)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    if let preset = profile.presetName {
                        TagBadge(text: preset, color: .accentColor)
                    }
                    if let formation = profile.formationName {
                        TagBadge(text: formation, color: .secondary)
                    }
                }

                let summary = triggerSummary(profile.trigger)
                if summary != "No trigger" {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 4) {
                Button("Edit") { onEdit() }
                    .controlSize(.small)
                Button("Delete") { onDelete() }
                    .controlSize(.small)
                    .foregroundStyle(.red)
            }
        }
        .padding(10)
        .background(.quaternary.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isActive ? Color.green.opacity(0.4) : Color.white.opacity(0.06),
                    lineWidth: isActive ? 1 : 0.5
                )
        )
    }

    private func triggerSummary(_ trigger: ProfileTrigger) -> String {
        var parts: [String] = []
        if let apps = trigger.apps, !apps.isEmpty {
            parts.append("Apps: \(apps.joined(separator: ", "))")
        }
        if let time = trigger.timeRange, !time.isEmpty {
            parts.append("Time: \(time)")
        }
        return parts.isEmpty ? "No trigger" : parts.joined(separator: " · ")
    }
}

// MARK: - Tag Badge

private struct TagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.2), lineWidth: 0.5))
    }
}

// MARK: - Profile Editor Sheet

private struct ProfileEditorSheet: View {
    let existing: Profile?
    let onSave: (Profile) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var selectedPreset: String = ""       // "" = None
    @State private var selectedFormation: String = ""   // "" = None
    @State private var appsText: String = ""
    @State private var timeRangeText: String = ""
    @State private var timeRangeValid: Bool = true

    private let formations: [(id: String, label: String)] = [
        ("full", "Full"),
        ("floating", "Floating"),
        ("islands", "Islands"),
        ("pills", "Pills"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Sheet header
            HStack {
                Text(existing == nil ? "New Profile" : "Edit Profile")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: - Name
                    EditorSection(title: "Name") {
                        TextField("e.g. Night Mode", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                    }

                    // MARK: - Appearance
                    EditorSection(title: "Appearance") {
                        HStack {
                            Text("Preset")
                                .frame(width: 90, alignment: .leading)
                                .foregroundStyle(.secondary)
                            Picker("", selection: $selectedPreset) {
                                Text("Default (no override)").tag("")
                                Divider()
                                ForEach(Preset.allCases, id: \.rawValue) { p in
                                    Text(presetDisplayName(p)).tag(p.rawValue)
                                }
                            }
                            .labelsHidden()
                            .frame(minWidth: 180)
                        }

                        HStack {
                            Text("Formation")
                                .frame(width: 90, alignment: .leading)
                                .foregroundStyle(.secondary)
                            Picker("", selection: $selectedFormation) {
                                Text("Default (no override)").tag("")
                                Divider()
                                ForEach(formations, id: \.id) { f in
                                    Text(f.label).tag(f.id)
                                }
                            }
                            .labelsHidden()
                            .frame(minWidth: 180)
                        }
                    }

                    // MARK: - Triggers
                    EditorSection(title: "Triggers") {
                        VStack(alignment: .leading, spacing: 12) {
                            // App trigger
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App names")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("Xcode, Terminal, Figma", text: $appsText)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 320)
                                Text("Comma-separated. Profile activates when any listed app is frontmost.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()

                            // Time trigger
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time range")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                HStack(spacing: 8) {
                                    TextField("HH:mm-HH:mm", text: $timeRangeText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 160)
                                        .onChange(of: timeRangeText) { _, newValue in
                                            timeRangeValid = newValue.isEmpty || isValidTimeRange(newValue)
                                        }
                                    if !timeRangeValid {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.yellow)
                                    }
                                }
                                Text("Format: HH:mm-HH:mm — e.g. 18:00-06:00 for evening/night. Supports overnight ranges.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            // MARK: - Sheet footer
            HStack {
                Spacer()
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || !timeRangeValid)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(width: 480, height: 540)
        .onAppear { populateFromExisting() }
    }

    // MARK: - Helpers

    private func populateFromExisting() {
        guard let p = existing else { return }
        name = p.name
        selectedPreset = p.presetName ?? ""
        selectedFormation = p.formationName ?? ""
        appsText = (p.trigger.apps ?? []).joined(separator: ", ")
        timeRangeText = p.trigger.timeRange ?? ""
        timeRangeValid = true
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, timeRangeValid else { return }

        let apps: [String]? = {
            let parts = appsText.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts
        }()

        let timeRange: String? = {
            let t = timeRangeText.trimmingCharacters(in: .whitespaces)
            return t.isEmpty ? nil : t
        }()

        let trigger = ProfileTrigger(apps: apps, timeRange: timeRange)
        let profile = Profile(
            id: existing?.id ?? UUID(),
            name: trimmedName,
            presetName: selectedPreset.isEmpty ? nil : selectedPreset,
            formationName: selectedFormation.isEmpty ? nil : selectedFormation,
            trigger: trigger
        )
        onSave(profile)
    }

    private func isValidTimeRange(_ s: String) -> Bool {
        let parts = s.split(separator: "-")
        guard parts.count == 2 else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: String(parts[0])) != nil
            && formatter.date(from: String(parts[1])) != nil
    }

    private func presetDisplayName(_ preset: Preset) -> String {
        switch preset {
        case .liquidGlass: return "Liquid Glass"
        case .frosted:     return "Frosted"
        case .flatDark:    return "Flat Dark"
        case .minimal:     return "Minimal"
        case .neon:        return "Neon"
        case .tokyoNight:  return "Tokyo Night"
        case .dracula:     return "Dracula"
        case .gruvbox:     return "Gruvbox"
        case .nord:        return "Nord"
        case .catppuccin:  return "Catppuccin"
        case .solarized:   return "Solarized"
        }
    }
}

// MARK: - Editor Section

private struct EditorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(14)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
