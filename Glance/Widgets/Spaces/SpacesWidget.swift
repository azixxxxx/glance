import SwiftUI

// MARK: - Display Mode & Highlight Style

enum SpacesDisplayMode: String {
    case icons         = "icons"        // Space number + app icons + focused window title (default)
    case numbers       = "numbers"      // Just space numbers in styled containers
    case dots          = "dots"         // Small circles: filled/hollow/focused
    case iconsOnly     = "icons-only"   // App icons only, no numbers
    case focusedOnly   = "focused-only" // Only show the focused space
}

enum SpacesHighlight: String {
    case opacity   // Focused 100%, inactive 60% (default)
    case pill      // Accent capsule background behind focused
    case underline // Colored bar beneath focused
    case glow      // Soft accent glow around focused
}

// MARK: - Spaces Widget

struct SpacesWidget: View {
    @StateObject var viewModel = SpacesViewModel()

    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }

    @Namespace private var highlightNamespace

    var body: some View {
        Group {
            if viewModel.isUnavailable {
                Text("Spaces unavailable")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: foregroundHeight < 30 ? 0 : 8) {
                    ForEach(viewModel.spaces) { space in
                        SpaceView(space: space, highlightNamespace: highlightNamespace)
                    }
                }
            }
        }
        .experimentalConfiguration(horizontalPadding: 5)
        .animation(.smooth(duration: 0.3), value: viewModel.spaces)
        .environmentObject(viewModel)
    }
}

// MARK: - Space View (routes to display mode)

private struct SpaceView: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @EnvironmentObject var viewModel: SpacesViewModel
    @Environment(\.appearance) private var appearance

    var config: ConfigData { configProvider.config }
    var spaceConfig: ConfigData { config["space"]?.dictionaryValue ?? [:] }

    @ObservedObject var configManager = ConfigManager.shared
    var foregroundHeight: CGFloat { configManager.config.experimental.foreground.resolveHeight() }

    var showKey: Bool { spaceConfig["show-key"]?.boolValue ?? true }

    var displayMode: SpacesDisplayMode {
        guard let raw = spaceConfig["display-mode"]?.stringValue else { return .icons }
        return SpacesDisplayMode(rawValue: raw) ?? .icons
    }

    var highlight: SpacesHighlight {
        guard let raw = spaceConfig["highlight"]?.stringValue else { return .opacity }
        return SpacesHighlight(rawValue: raw) ?? .opacity
    }

    let space: AnySpace
    let highlightNamespace: Namespace.ID

    @State var isHovered = false

    var body: some View {
        let isFocused = space.windows.contains { $0.isFocused } || space.isFocused
        let isOccupied = !space.windows.isEmpty

        // In focused-only mode, hide non-focused spaces
        if displayMode == .focusedOnly && !isFocused {
            EmptyView()
        } else {
            spaceContent(isFocused: isFocused, isOccupied: isOccupied)
                .highlightStyle(
                    highlight,
                    isFocused: isFocused,
                    isHovered: isHovered,
                    accentColor: appearance.accentColor,
                    namespace: highlightNamespace
                )
                .contentShape(Rectangle())
                .transition(.blurReplace)
                .onTapGesture {
                    FeedbackManager.shared.tock()
                    viewModel.switchToSpace(space, needWindowFocus: true)
                }
                .animation(.smooth, value: isHovered)
                .animation(.smooth, value: isFocused)
                .onHover { value in
                    isHovered = value
                }
        }
    }

    @ViewBuilder
    private func spaceContent(isFocused: Bool, isOccupied: Bool) -> some View {
        switch displayMode {
        case .icons, .focusedOnly:
            iconsContent(isFocused: isFocused)
        case .numbers:
            numbersContent(isFocused: isFocused)
        case .dots:
            dotsContent(isFocused: isFocused, isOccupied: isOccupied)
        case .iconsOnly:
            iconsOnlyContent(isFocused: isFocused)
        }
    }

    // MARK: - Icons Mode (default — number + app icons + title)

    @ViewBuilder
    private func iconsContent(isFocused: Bool) -> some View {
        HStack(spacing: 4) {
            if showKey {
                Text(space.id)
                    .font(.system(size: 12, weight: isFocused ? .bold : .regular))
                    .foregroundStyle(isFocused ? Color.white : Color.gray)
                    .frame(minWidth: 12)
                    .fixedSize(horizontal: true, vertical: false)
            }
            HStack(spacing: 2) {
                ForEach(space.windows) { window in
                    WindowView(window: window, space: space)
                }
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 30)
    }

    // MARK: - Numbers Mode (just space numbers)

    @ViewBuilder
    private func numbersContent(isFocused: Bool) -> some View {
        Text(space.id)
            .font(.system(size: 12, weight: isFocused ? .bold : .medium, design: .rounded))
            .foregroundStyle(isFocused ? Color.white : Color.gray)
            .frame(minWidth: 20, minHeight: 20)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 4)
            .frame(height: 30)
    }

    // MARK: - Dots Mode (circles: focused/occupied/empty)

    @ViewBuilder
    private func dotsContent(isFocused: Bool, isOccupied: Bool) -> some View {
        let dotSize: CGFloat = isFocused ? 8 : 6

        Circle()
            .fill(isFocused ? appearance.accentColor : (isOccupied ? Color.white.opacity(0.7) : Color.white.opacity(0.25)))
            .frame(width: dotSize, height: dotSize)
            .animation(.smooth(duration: 0.2), value: isFocused)
            .padding(.horizontal, 3)
            .frame(height: 30)
    }

    // MARK: - Icons Only Mode (app icons, no numbers)

    @ViewBuilder
    private func iconsOnlyContent(isFocused: Bool) -> some View {
        HStack(spacing: 2) {
            if space.windows.isEmpty {
                // Show a small placeholder dot for empty spaces
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 6, height: 6)
            } else {
                ForEach(space.windows) { window in
                    WindowView(window: window, space: space)
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 30)
    }
}

// MARK: - Highlight Style Modifier

private struct HighlightModifier: ViewModifier {
    let style: SpacesHighlight
    let isFocused: Bool
    let isHovered: Bool
    let accentColor: Color
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        switch style {
        case .opacity:
            content
                .opacity(isFocused ? 1.0 : (isHovered ? 0.9 : 0.6))

        case .pill:
            content
                .background(
                    Group {
                        if isFocused {
                            Capsule()
                                .fill(accentColor.opacity(0.3))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(accentColor.opacity(0.4), lineWidth: 0.5)
                                )
                                .matchedGeometryEffect(id: "spaceHighlight", in: namespace)
                        } else {
                            Capsule()
                                .fill(Color.clear)
                        }
                    }
                )
                .opacity(isFocused ? 1.0 : (isHovered ? 0.85 : 0.55))

        case .underline:
            content
                .overlay(alignment: .bottom) {
                    if isFocused {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(accentColor)
                            .frame(width: 16, height: 2.5)
                            .offset(y: -2)
                            .matchedGeometryEffect(id: "spaceHighlight", in: namespace)
                    }
                }
                .opacity(isFocused ? 1.0 : (isHovered ? 0.85 : 0.55))

        case .glow:
            content
                .shadow(color: isFocused ? accentColor.opacity(0.6) : .clear, radius: isFocused ? 6 : 0)
                .opacity(isFocused ? 1.0 : (isHovered ? 0.85 : 0.5))
        }
    }
}

private extension View {
    func highlightStyle(
        _ style: SpacesHighlight,
        isFocused: Bool,
        isHovered: Bool,
        accentColor: Color,
        namespace: Namespace.ID
    ) -> some View {
        modifier(HighlightModifier(
            style: style,
            isFocused: isFocused,
            isHovered: isHovered,
            accentColor: accentColor,
            namespace: namespace
        ))
    }
}

// MARK: - Window View (icon + optional title)

private struct WindowView: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @EnvironmentObject var viewModel: SpacesViewModel

    var config: ConfigData { configProvider.config }
    var windowConfig: ConfigData { config["window"]?.dictionaryValue ?? [:] }
    var titleConfig: ConfigData {
        windowConfig["title"]?.dictionaryValue ?? [:]
    }

    var showTitle: Bool { windowConfig["show-title"]?.boolValue ?? true }
    var maxLength: Int { titleConfig["max-length"]?.intValue ?? 50 }
    var alwaysDisplayAppTitleFor: [String] { titleConfig["always-display-app-name-for"]?.arrayValue?.filter({ $0.stringValue != nil }).map { $0.stringValue! } ?? [] }

    let window: AnyWindow
    let space: AnySpace

    @State var isHovered = false

    var body: some View {
        let titleMaxLength = maxLength
        let size: CGFloat = 21
        let sameAppCount = space.windows.filter { $0.appName == window.appName }
            .count
        let title = sameAppCount > 1 && !alwaysDisplayAppTitleFor.contains { $0 == window.appName } ? window.title : (window.appName ?? "")
        let spaceIsFocused = space.windows.contains { $0.isFocused }
        HStack {
            ZStack {
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: size, height: size)
                        .shadow(
                            color: .black.opacity(0.3),
                            radius: 2
                        )
                } else {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: size, height: size)
                }
            }
            .opacity(spaceIsFocused && !window.isFocused ? 0.5 : 1)
            .transition(.blurReplace)

            if window.isFocused, !title.isEmpty, showTitle {
                HStack {
                    Text(
                        title.count > titleMaxLength
                            ? String(title.prefix(titleMaxLength)) + "..."
                            : title
                    )
                    .fixedSize(horizontal: true, vertical: false)
                    .shadow(color: .black.opacity(0.3), radius: 3)
                    .fontWeight(.semibold)
                    Spacer().frame(width: 5)
                }
                .transition(.blurReplace)
            }
        }
        .padding(.all, 1)
        .background(isHovered || (!showTitle && window.isFocused) ? .selected : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .animation(.smooth, value: isHovered)
        .frame(height: 30)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.switchToSpace(space)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.switchToWindow(window)
            }
        }
        .onHover { value in
            isHovered = value
        }
    }
}
