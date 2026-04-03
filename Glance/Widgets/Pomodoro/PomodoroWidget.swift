import SwiftUI

struct PomodoroWidget: View {
    @EnvironmentObject var configProvider: ConfigProvider
    @StateObject private var viewModel = PomodoroViewModel()
    @State private var rect: CGRect = .zero

    var body: some View {
        Group {
            if viewModel.currentState != .idle {
                HStack(spacing: 4) {
                    Image(systemName: stateIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(stateColor)
                        .symbolEffect(.pulse, options: .repeating, isActive: isLastMinute)
                    Text(viewModel.timeString)
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(isLastMinute ? .red : .primary)
                }
                .shadow(color: .black.opacity(0.3), radius: 3)
                .experimentalConfiguration(horizontalPadding: 10)
            } else {
                Image(systemName: "timer")
                    .font(.system(size: 13))
                    .shadow(color: .black.opacity(0.3), radius: 3)
                    .experimentalConfiguration(horizontalPadding: 8)
            }
        }
        .frame(maxHeight: .infinity)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { rect = geo.frame(in: .global) }
                    .onChange(of: geo.frame(in: .global)) { _, newValue in
                        rect = newValue
                    }
            }
        )
        .background(.black.opacity(0.001))
        .onTapGesture {
            MenuBarPopup.show(rect: rect, id: "pomodoro") {
                PomodoroPopup(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.configure(from: configProvider.config)
        }
        .onReceive(configProvider.objectWillChange) { _ in
            viewModel.configure(from: configProvider.config)
        }
    }

    private var stateIcon: String {
        switch viewModel.currentState {
        case .idle: return "timer"
        case .work: return "brain.head.profile"
        case .shortBreak, .longBreak: return "cup.and.saucer.fill"
        }
    }

    private var isLastMinute: Bool {
        viewModel.currentState == .work && viewModel.remainingSeconds > 0 && viewModel.remainingSeconds <= 60
    }

    private var stateColor: Color {
        switch viewModel.currentState {
        case .idle: return .primary
        case .work: return .red
        case .shortBreak: return .green
        case .longBreak: return .blue
        }
    }
}
