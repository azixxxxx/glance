import SwiftUI

/// Widget for the menu, displaying Wi‑Fi and Ethernet icons.
struct NetworkWidget: View {
    @StateObject private var viewModel = NetworkStatusViewModel()
    @State private var rect: CGRect = .zero

    var body: some View {
        HStack(spacing: 15) {
            if viewModel.wifiState != .notSupported {
                wifiIcon
            }
            if viewModel.ethernetState != .notSupported {
                ethernetIcon
            }
        }
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
        .font(.system(size: 15))
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
            Image(systemName: "wifi")
        case .connecting:
            Image(systemName: "wifi")
                .foregroundStyle(.yellow)
        case .connectedWithoutInternet:
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(.yellow)
        case .disconnected:
            Image(systemName: "wifi.slash")
                .opacity(0.5)
        case .disabled:
            Image(systemName: "wifi.slash")
                .foregroundStyle(.red)
        case .notSupported:
            Image(systemName: "wifi.exclamationmark")
                .opacity(0.5)
        }
    }

    @ViewBuilder
    private var ethernetIcon: some View {
        switch viewModel.ethernetState {
        case .connected:
            Image(systemName: "network")
        case .connectedWithoutInternet:
            Image(systemName: "network")
                .foregroundStyle(.yellow)
        case .connecting:
            Image(systemName: "network.slash")
                .foregroundStyle(.yellow)
        case .disconnected:
            Image(systemName: "network.slash")
                .foregroundStyle(.red)
        case .disabled, .notSupported:
            Image(systemName: "questionmark.circle")
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
