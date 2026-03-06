import Combine
import Foundation
import IOKit.ps

/// This class monitors the battery status.
class BatteryManager: ObservableObject {
    @Published var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var cycleCount: Int = 0
    @Published var healthPercent: Int = 100
    @Published var temperature: Double = 0  // Celsius
    @Published var timeRemaining: Int? = nil  // minutes, nil if unknown
    @Published var powerSource: String = "Battery"
    @Published var maxCapacity: Int = 0
    @Published var designCapacity: Int = 0
    private var timer: Timer?

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    private func startMonitoring() {
        // Update every 1 second.
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] _ in
            self?.updateBatteryStatus()
        }
        updateBatteryStatus()
        updateBatteryHealth()
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    /// This method updates the battery level and charging state.
    func updateBatteryStatus() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?
                .takeRetainedValue() as? [CFTypeRef]
        else {
            return
        }

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(
                snapshot, source)?.takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[
                    kIOPSCurrentCapacityKey as String] as? Int,
                let maxCap = description[kIOPSMaxCapacityKey as String]
                    as? Int,
                let charging = description[kIOPSIsChargingKey as String]
                    as? Bool,
                let powerSourceState = description[
                    kIOPSPowerSourceStateKey as String] as? String
            {
                let isAC = (powerSourceState == kIOPSACPowerValue)

                DispatchQueue.main.async {
                    self.batteryLevel = (currentCapacity * 100) / maxCap
                    self.isCharging = charging
                    self.isPluggedIn = isAC
                    self.powerSource = isAC ? "AC Power" : "Battery"
                }
            }
        }

        // Time remaining estimate
        let timeRemainingSeconds = IOPSGetTimeRemainingEstimate()
        DispatchQueue.main.async {
            if timeRemainingSeconds == kIOPSTimeRemainingUnlimited {
                self.timeRemaining = nil  // plugged in, fully charged
            } else if timeRemainingSeconds == kIOPSTimeRemainingUnknown {
                self.timeRemaining = nil
            } else {
                self.timeRemaining = Int(timeRemainingSeconds / 60)
            }
        }
    }

    /// Reads battery health data from IOKit SmartBattery.
    func updateBatteryHealth() {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any]
        else { return }

        DispatchQueue.main.async {
            if let cycles = dict["CycleCount"] as? Int {
                self.cycleCount = cycles
            }

            if let maxCap = dict["MaxCapacity"] as? Int,
               let designCap = dict["DesignCapacity"] as? Int,
               designCap > 0
            {
                self.maxCapacity = maxCap
                self.designCapacity = designCap
                self.healthPercent = (maxCap * 100) / designCap
            }

            if let temp = dict["Temperature"] as? Int {
                // Temperature is in 1/100 degree Celsius
                self.temperature = Double(temp) / 100.0
            }
        }

        // Refresh health every 30 seconds (separate timer not needed, called once)
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.updateBatteryHealth()
        }
    }

    /// Format time remaining as "H:MM"
    static func formatTimeRemaining(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%d:%02d", hours, mins)
    }
}
