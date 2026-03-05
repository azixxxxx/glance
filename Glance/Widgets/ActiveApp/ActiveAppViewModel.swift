import AppKit
import Combine

final class ActiveAppViewModel: ObservableObject {
    @Published var appName: String = ""
    @Published var appIcon: NSImage?

    private var cancellable: AnyCancellable?

    init() {
        updateActiveApp()

        cancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateActiveApp()
            }
    }

    private func updateActiveApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        appName = app.localizedName ?? ""
        if let bundleURL = app.bundleURL {
            appIcon = NSWorkspace.shared.icon(forFile: bundleURL.path)
        }
    }
}
