import SwiftUI

/// A single quick action button.
struct QuickAction {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
}

/// Compact horizontal strip of icon buttons for long-press quick actions.
struct QuickActionsView: View {
    let title: String
    let actions: [QuickAction]

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                    Button {
                        FeedbackManager.shared.tock()
                        action.action()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(action.isActive ? Color.accentColor : .primary)
                            Text(action.label)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
    }
}
