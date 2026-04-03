import SwiftUI

/// Widget for the menu, displaying Wi‑Fi and Ethernet icons.
struct NetworkWidget: View {
    @ObservedObject private var viewModel = NetworkStatusViewModel.shared
    @State private var rect: CGRect = .zero

    var body: some View {
        HStack(spacing: 12) {
            if viewModel.wifiState != .notSupported {
                wifiIcon
            }
            if viewModel.ethernetState != .notSupported {
                ethernetIcon
            }
        }
        .barSingleLineAligned()
        .badge(count: viewModel.wifiSignalStrength == .low ? 0 : nil, color: .yellow)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { rect = geometry.frame(in: .global) }
                    .onChange(of: geometry.frame(in: .global)) { _, newValue in
                        rect = newValue
                    }
            }
        )
        .contentShape(Rectangle())
        .experimentalConfiguration()
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.001))
        .onTapGesture {
            MenuBarPopup.show(rect: rect, id: "network") { NetworkPopup() }
        }
    }

    @ViewBuilder
    private var wifiIcon: some View {
        switch viewModel.wifiState {
        case .connected:
            Image(systemName: "wifi").barStatusSymbol(opticalYOffset: -0.45)
        case .connecting:
            Image(systemName: "wifi")
                .barStatusSymbol(opticalYOffset: -0.45)
                .foregroundStyle(.yellow)
        case .connectedWithoutInternet:
            Image(systemName: "wifi.exclamationmark")
                .barStatusSymbol(opticalYOffset: -0.25)
                .foregroundStyle(.yellow)
        case .disconnected:
            Image(systemName: "wifi.slash")
                .barStatusSymbol(opticalYOffset: -0.35)
                .opacity(0.5)
        case .disabled:
            Image(systemName: "wifi.slash")
                .barStatusSymbol(opticalYOffset: -0.35)
                .foregroundStyle(.red)
        case .notSupported:
            Image(systemName: "wifi.exclamationmark")
                .barStatusSymbol(opticalYOffset: -0.25)
                .opacity(0.5)
        }
    }

    @ViewBuilder
    private var ethernetIcon: some View {
        switch viewModel.ethernetState {
        case .connected:
            Image(systemName: "network").barStatusSymbol(opticalYOffset: -0.2)
        case .connectedWithoutInternet:
            Image(systemName: "network")
                .barStatusSymbol(opticalYOffset: -0.2)
                .foregroundStyle(.yellow)
        case .connecting:
            Image(systemName: "network.slash")
                .barStatusSymbol(opticalYOffset: -0.1)
                .foregroundStyle(.yellow)
        case .disconnected:
            Image(systemName: "network.slash")
                .barStatusSymbol(opticalYOffset: -0.1)
                .foregroundStyle(.red)
        case .disabled, .notSupported:
            Image(systemName: "questionmark.circle")
                .barStatusSymbol(opticalYOffset: -0.1)
                .opacity(0.5)
        }
    }
}

struct NetworkWidget_Previews: PreviewProvider {
    static var previews: some View {
        NetworkWidget()
            .frame(width: 200, height: 100)
            .background(Color.black)
    }
}
