import SwiftUI

struct BatteryPopup: View {
    @StateObject private var batteryManager = BatteryManager()
    @ObservedObject var configManager = ConfigManager.shared
    var appearance: AppearanceConfig { configManager.config.appearance }

    var body: some View {
        VStack(spacing: 14) {
            // Ring progress
            ZStack {
                Circle()
                    .stroke(appearance.foregroundColor.opacity(0.12), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(batteryManager.batteryLevel) / 100)
                    .stroke(
                        batteryColor,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeOut(duration: 0.5), value: batteryManager.batteryLevel)

                VStack(spacing: 2) {
                    if batteryManager.isPluggedIn {
                        Image(systemName: batteryManager.isCharging ? "bolt.fill" : "powerplug.portrait.fill")
                            .font(.system(size: 10))
                            .opacity(0.6)
                            .transition(.blurReplace)
                    }
                    Text("\(batteryManager.batteryLevel)%")
                        .font(.system(size: 16, weight: .semibold))
                        .monospacedDigit()
                }
            }
            .frame(width: 64, height: 64)

            // Details
            Divider().opacity(0.15)

            VStack(alignment: .leading, spacing: 5) {
                detailRow("Health", "\(batteryManager.healthPercent)%", color: healthColor)
                detailRow("Cycles", "\(batteryManager.cycleCount)")
                if batteryManager.temperature > 0 {
                    detailRow("Temperature", String(format: "%.1f°C", batteryManager.temperature))
                }
                detailRow("Power", batteryManager.powerSource)
                if let time = batteryManager.timeRemaining {
                    detailRow(
                        batteryManager.isCharging ? "Until Full" : "Remaining",
                        BatteryManager.formatTimeRemaining(time)
                    )
                }
            }
            .font(.system(size: 12))
            .opacity(0.7)
        }
        .frame(width: 180)
        .padding(22)
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .opacity(0.5)
            Spacer()
            if let color = color {
                Text(value)
                    .foregroundStyle(color)
            } else {
                Text(value)
            }
        }
    }

    private var batteryColor: Color {
        if batteryManager.isCharging {
            return .green
        } else if batteryManager.batteryLevel <= 10 {
            return .red
        } else if batteryManager.batteryLevel <= 20 {
            return .yellow
        } else {
            return appearance.accentColor
        }
    }

    private var healthColor: Color {
        if batteryManager.healthPercent >= 80 {
            return .green
        } else if batteryManager.healthPercent >= 50 {
            return .yellow
        } else {
            return .red
        }
    }
}
