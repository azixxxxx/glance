import AppKit
import Combine

final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published var profiles: [Profile] = [] {
        didSet { save(); evaluate() }
    }
    @Published private(set) var activeProfile: Profile?

    private var appObserver: Any?
    private var timeTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let defaultsKey = "glance.profiles"

    private init() {
        load()
        startMonitoring()

        // When activeProfile changes, trigger Config re-render
        $activeProfile
            .receive(on: DispatchQueue.main)
            .sink { _ in
                ConfigManager.shared.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD

    func add(_ profile: Profile) {
        profiles.append(profile)
    }

    func update(_ profile: Profile) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[idx] = profile
    }

    func delete(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
    }

    // MARK: - Persistence (UserDefaults JSON)

    private func save() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([Profile].self, from: data)
        else { return }
        profiles = decoded
    }

    // MARK: - Trigger Monitoring

    private func startMonitoring() {
        // App activation
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let name = app.localizedName
            else { return }
            self?.evaluateAppTrigger(name)
        }

        // Time-based (check every 60 seconds)
        timeTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.evaluate()
        }

        // Initial evaluation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.evaluate()
        }
    }

    // MARK: - Evaluation

    private func evaluateAppTrigger(_ appName: String) {
        // App triggers have highest priority
        for profile in profiles {
            if profile.trigger.matchesApp(appName) {
                setActive(profile)
                return
            }
        }
        // No app match — fall back to time-based or nil
        evaluateTimeTrigger()
    }

    private func evaluateTimeTrigger() {
        for profile in profiles where profile.trigger.timeRange != nil {
            if profile.trigger.matchesCurrentTime() {
                setActive(profile)
                return
            }
        }
        // No triggers matched
        setActive(nil)
    }

    private func evaluate() {
        // Check if current frontmost app matches any profile
        if let app = NSWorkspace.shared.frontmostApplication?.localizedName {
            evaluateAppTrigger(app)
        } else {
            evaluateTimeTrigger()
        }
    }

    private func setActive(_ profile: Profile?) {
        guard activeProfile?.id != profile?.id else { return }
        activeProfile = profile
    }
}
