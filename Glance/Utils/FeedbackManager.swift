import AppKit

final class FeedbackManager {
    static let shared = FeedbackManager()

    private let hapticPerformer = NSHapticFeedbackManager.defaultPerformer

    private init() {}

    /// Light alignment haptic — for scroll steps, small state changes.
    func tick() {
        guard ConfigManager.shared.config.feedback.haptics else { return }
        hapticPerformer.perform(.alignment, performanceTime: .now)
    }

    /// Generic haptic — for button presses, space switches.
    func tock() {
        guard ConfigManager.shared.config.feedback.haptics else { return }
        hapticPerformer.perform(.generic, performanceTime: .now)
    }
}
