import SwiftUI

/// Displays a small notification badge (dot or count) at the top-right corner of any widget.
/// - `nil` count = no badge
/// - `0` count = dot only
/// - `>0` count = number
struct BadgeModifier: ViewModifier {
    let count: Int?
    var color: Color = .red

    func body(content: Content) -> some View {
        content.overlay(alignment: .topTrailing) {
            if let count {
                Group {
                    if count == 0 {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                    } else {
                        Text("\(min(count, 99))")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(color, in: Capsule())
                            .fixedSize()
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .offset(x: 3, y: -2)
            }
        }
        .animation(.spring(duration: 0.3), value: count)
    }
}

extension View {
    func badge(count: Int?, color: Color = .red) -> some View {
        modifier(BadgeModifier(count: count, color: color))
    }
}
