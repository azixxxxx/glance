import SwiftUI

struct NetworkPopup: View {
    @StateObject private var viewModel = NetworkStatusViewModel()
    @ObservedObject var configManager = ConfigManager.shared
    var appearance: AppearanceConfig { configManager.config.appearance }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if viewModel.wifiState != .notSupported {
                // Wi-Fi header: SSID + band badge
                HStack(spacing: 10) {
                    Image(systemName: wifiIconName)
                        .font(.system(size: 14))
                        .foregroundStyle(wifiStatusColor)
                    Text(viewModel.ssid)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    if !viewModel.bandLabel.isEmpty
                        && viewModel.ssid != "Not connected"
                        && viewModel.ssid != "No interface"
                    {
                        Text(viewModel.bandLabel)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(appearance.accentColor.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                if viewModel.ssid != "Not connected" && viewModel.ssid != "No interface" {
                    // Signal strength visual
                    HStack(spacing: 8) {
                        SignalBarsView(
                            bars: viewModel.wifiSignalStrength.signalBars,
                            accentColor: appearance.accentColor,
                            foregroundColor: appearance.foregroundColor
                        )
                        Text("\(viewModel.rssi) dBm")
                            .font(.system(size: 12, design: .monospaced))
                            .opacity(0.5)
                        Spacer()
                        Text(viewModel.wifiSignalStrength.qualityLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(wifiStatusColor)
                    }

                    // Live speed
                    HStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(appearance.accentColor)
                            Text(NetworkStatusViewModel.formatSpeed(viewModel.downloadSpeed))
                                .font(.system(size: 12, design: .monospaced))
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(appearance.accentColor)
                            Text(NetworkStatusViewModel.formatSpeed(viewModel.uploadSpeed))
                                .font(.system(size: 12, design: .monospaced))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(appearance.foregroundColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Details table
                    Divider().opacity(0.15)

                    VStack(alignment: .leading, spacing: 5) {
                        detailRow("IP", viewModel.localIP)
                        detailRow("Channel", viewModel.channel)
                        if viewModel.txRate > 0 {
                            detailRow("Tx Rate", "\(Int(viewModel.txRate)) Mbps")
                        }
                        detailRow("Noise", "\(viewModel.noise) dBm")
                    }
                    .font(.system(size: 12))
                    .opacity(0.7)
                }
            }

            if viewModel.ethernetState != .notSupported {
                if viewModel.wifiState != .notSupported {
                    Divider().opacity(0.15)
                }
                HStack(spacing: 10) {
                    Image(systemName: "network")
                        .font(.system(size: 14))
                        .foregroundStyle(ethernetStatusColor)
                    Text("Ethernet")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(viewModel.ethernetState.rawValue)
                        .font(.subheadline)
                        .opacity(0.6)
                }
            }
        }
        .frame(width: 240)
        .padding(22)
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .opacity(0.5)
            Spacer()
            Text(value)
                .font(.system(size: 12, design: .monospaced))
        }
    }

    private var wifiIconName: String {
        switch viewModel.wifiState {
        case .connected: return "wifi"
        case .connecting: return "wifi"
        case .connectedWithoutInternet: return "wifi.exclamationmark"
        case .disconnected, .disabled: return "wifi.slash"
        case .notSupported: return "wifi.exclamationmark"
        }
    }

    private var wifiStatusColor: Color {
        switch viewModel.wifiState {
        case .connected: return appearance.accentColor
        case .connecting, .connectedWithoutInternet: return .yellow
        case .disconnected: return appearance.foregroundColor.opacity(0.4)
        case .disabled: return .red
        case .notSupported: return appearance.foregroundColor.opacity(0.4)
        }
    }

    private var ethernetStatusColor: Color {
        switch viewModel.ethernetState {
        case .connected: return appearance.accentColor
        case .connecting, .connectedWithoutInternet: return .yellow
        case .disconnected: return .red
        case .disabled, .notSupported: return appearance.foregroundColor.opacity(0.4)
        }
    }
}

// MARK: - Signal Bars

private struct SignalBarsView: View {
    let bars: Int  // 0-3
    let accentColor: Color
    let foregroundColor: Color

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < bars ? accentColor : foregroundColor.opacity(0.15))
                    .frame(width: 4, height: CGFloat(6 + index * 4))
            }
        }
        .frame(height: 14, alignment: .bottom)
    }
}
