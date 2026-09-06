import Combine
import Foundation
import IOKit.ps
import AppKit

/// This class monitors the battery status.
final class BatteryManager: ObservableObject {
    static let shared = BatteryManager()

    @Published var batteryLevel: Int = 0
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var cycleCount: Int = 0
    @Published var healthPercent: Int? = nil
    @Published var temperature: Double = 0  // Celsius
    @Published var timeRemaining: Int? = nil  // minutes, nil if unknown
    @Published var powerSource: String = "Battery"
    @Published var maxCapacity: Int = 0
    @Published var designCapacity: Int = 0
    private var timer: Timer?
    private var lastHealthRead = Date.distantPast
    private var wakeObserver: NSObjectProtocol?
    private let logger = AppLogger.shared
    private var hasLoggedMissingPowerSnapshot = false
    private var hasLoggedMissingSmartBattery = false

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    private func startMonitoring() {
        // Update every 30 seconds — battery level changes roughly once per minute.
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) {
            [weak self] _ in
            self?.refresh()
        }
        timer?.tolerance = 5

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }

        refresh()
    }

    private func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        updateBatteryStatus()
        updateBatteryHealth()
    }

    /// This method updates the battery level and charging state.
    func updateBatteryStatus() {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let sources = IOPSCopyPowerSourcesList(snapshot)?
                .takeRetainedValue() as? [CFTypeRef]
        else {
            if !hasLoggedMissingPowerSnapshot {
                logger.warning("Failed to read power source snapshot", category: .battery)
                hasLoggedMissingPowerSnapshot = true
            }
            return
        }
        hasLoggedMissingPowerSnapshot = false

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
                let safeMaxCap = max(maxCap, 1)

                DispatchQueue.main.async {
                    self.batteryLevel = (currentCapacity * 100) / safeMaxCap
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
        refreshReportedHealth()
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != IO_OBJECT_NULL else {
            if !hasLoggedMissingSmartBattery {
                logger.warning("AppleSmartBattery service unavailable", category: .battery)
                hasLoggedMissingSmartBattery = true
            }
            return
        }
        hasLoggedMissingSmartBattery = false
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any]
        else {
            logger.warning("Failed to read battery health properties", category: .battery)
            return
        }

        DispatchQueue.main.async {
            if let cycles = dict["CycleCount"] as? Int {
                self.cycleCount = cycles
            }

            // MaxCapacity may be normalized to 100 on Apple Silicon, not mAh.
            if let maxCap = dict["NominalChargeCapacity"] as? Int ?? dict["AppleRawMaxCapacity"] as? Int,
               let designCap = dict["DesignCapacity"] as? Int,
               designCap > 0
            {
                self.maxCapacity = maxCap
                self.designCapacity = designCap
            }

            if let temp = dict["Temperature"] as? Int {
                // Temperature is in 1/100 degree Celsius
                self.temperature = Double(temp) / 100.0
            }
        }
    }

    /// Use the same reported maximum capacity as System Information. Raw charge
    /// capacity ratios fluctuate and are not Apple's battery health percentage.
    private func refreshReportedHealth() {
        guard Date().timeIntervalSince(lastHealthRead) >= 300 else { return }
        lastHealthRead = Date()
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process()
            let output = Pipe()
            let completion = DispatchSemaphore(value: 0)
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            process.arguments = ["SPPowerDataType", "-json"]
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { _ in completion.signal() }
            do {
                try process.run()
                guard completion.wait(timeout: .now() + 15) == .success else {
                    process.terminate()
                    return
                }
                guard process.terminationStatus == 0 else { return }
                let data = output.fileHandleForReading.readDataToEndOfFile()
                let health = Self.reportedHealth(from: data)
                DispatchQueue.main.async { self?.healthPercent = health }
            } catch {
                // Unavailable health stays unknown instead of inventing 100%.
            }
        }
    }

    static func reportedHealth(from data: Data) -> Int? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = root["SPPowerDataType"] as? [[String: Any]] else { return nil }
        for device in devices {
            guard let info = device["sppower_battery_health_info"] as? [String: Any],
                  let raw = info["sppower_battery_health_maximum_capacity"] as? String,
                  let value = Int(raw.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)),
                  (0...100).contains(value) else { continue }
            return value
        }
        return nil
    }

    /// Format time remaining as "H:MM"
    static func formatTimeRemaining(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%d:%02d", hours, mins)
    }
}
