import SwiftUI

struct SystemMonitorWidget: View {
    @ObservedObject private var viewModel = SystemMonitorViewModel.shared
    @State private var rect: CGRect = .zero

    var body: some View {
        HStack(spacing: 6) {
            // CPU
            HStack(spacing: 3) {
                Image(systemName: "cpu")
                    .barStatusSymbol(size: 11, opticalYOffset: -0.1)
                Text(String(format: "%.0f%%", viewModel.cpuUsage))
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }

            // Memory
            HStack(spacing: 3) {
                Image(systemName: "memorychip")
                    .barStatusSymbol(size: 11, opticalYOffset: -0.1)
                Text(String(format: "%.1f", viewModel.memoryUsedGB) + "G")
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
            }
        }
        .barSingleLineAligned()
        .shadow(color: .black.opacity(0.3), radius: 3)
        .shadow(color: viewModel.cpuUsage > 80 ? .orange.opacity(0.5) : .clear, radius: 6)
        .badge(count: viewModel.cpuUsage > 90 ? 0 : nil)
        .experimentalConfiguration(horizontalPadding: 10)
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
            MenuBarPopup.show(rect: rect, id: "systemmonitor") {
                SystemMonitorPopup(viewModel: viewModel)
            }
        }
        .animation(.smooth(duration: 0.3), value: viewModel.cpuUsage)
    }
}
