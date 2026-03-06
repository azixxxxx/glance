import CoreLocation
import CoreWLAN
import Network
import SwiftUI

enum NetworkState: String {
    case connected = "Connected"
    case connectedWithoutInternet = "No Internet"
    case connecting = "Connecting"
    case disconnected = "Disconnected"
    case disabled = "Disabled"
    case notSupported = "Not Supported"
}

enum WifiSignalStrength: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case unknown = "Unknown"

    var signalBars: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        case .unknown: return 0
        }
    }

    var qualityLabel: String {
        switch self {
        case .high: return "Excellent"
        case .medium: return "Good"
        case .low: return "Weak"
        case .unknown: return "N/A"
        }
    }
}

/// Unified view model for monitoring network and Wi‑Fi status.
final class NetworkStatusViewModel: NSObject, ObservableObject,
    CLLocationManagerDelegate
{

    // States for Wi‑Fi and Ethernet obtained via NWPathMonitor.
    @Published var wifiState: NetworkState = .disconnected
    @Published var ethernetState: NetworkState = .disconnected

    // Wi‑Fi details obtained via CoreWLAN.
    @Published var ssid: String = "Not connected"
    @Published var rssi: Int = 0
    @Published var noise: Int = 0
    @Published var channel: String = "N/A"
    @Published var bandLabel: String = ""
    @Published var txRate: Double = 0  // Mbps

    // Network speed tracking
    @Published var downloadSpeed: Double = 0  // bytes/s
    @Published var uploadSpeed: Double = 0    // bytes/s
    private var previousBytesIn: UInt64 = 0
    private var previousBytesOut: UInt64 = 0
    private var speedTimer: Timer?

    // Local IP
    @Published var localIP: String = "N/A"

    /// Computed property for signal strength.
    var wifiSignalStrength: WifiSignalStrength {
        // If Wi‑Fi is not connected or the interface is missing – return unknown.
        if ssid == "Not connected" || ssid == "No interface" {
            return .unknown
        }
        if rssi >= -50 {
            return .high
        } else if rssi >= -70 {
            return .medium
        } else {
            return .low
        }
    }

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    private var timer: Timer?
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        startNetworkMonitoring()
        startWiFiMonitoring()
        startSpeedMonitoring()
        updateLocalIP()
    }

    deinit {
        stopNetworkMonitoring()
        stopWiFiMonitoring()
        speedTimer?.invalidate()
    }

    // MARK: — NWPathMonitor for overall network status.

    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Wi‑Fi
                if path.availableInterfaces.contains(where: { $0.type == .wifi }
                ) {
                    if path.usesInterfaceType(.wifi) {
                        switch path.status {
                        case .satisfied:
                            self.wifiState = .connected
                        case .requiresConnection:
                            self.wifiState = .connecting
                        default:
                            self.wifiState = .connectedWithoutInternet
                        }
                    } else {
                        // If the Wi‑Fi interface is available but not in use – consider it enabled but not connected.
                        self.wifiState = .disconnected
                    }
                } else {
                    self.wifiState = .notSupported
                }

                // Ethernet
                if path.availableInterfaces.contains(where: {
                    $0.type == .wiredEthernet
                }) {
                    if path.usesInterfaceType(.wiredEthernet) {
                        switch path.status {
                        case .satisfied:
                            self.ethernetState = .connected
                        case .requiresConnection:
                            self.ethernetState = .connecting
                        default:
                            self.ethernetState = .disconnected
                        }
                    } else {
                        self.ethernetState = .disconnected
                    }
                } else {
                    self.ethernetState = .notSupported
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func stopNetworkMonitoring() {
        monitor.cancel()
    }

    // MARK: — Updating Wi‑Fi information via CoreWLAN.

    private func startWiFiMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) {
            [weak self] _ in
            self?.updateWiFiInfo()
        }
        updateWiFiInfo()
    }

    private func stopWiFiMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateWiFiInfo() {
        let client = CWWiFiClient.shared()
        if let interface = client.interface() {
            self.ssid = interface.ssid() ?? "Not connected"
            self.rssi = interface.rssiValue()
            self.noise = interface.noiseMeasurement()
            self.txRate = interface.transmitRate()
            if let wlanChannel = interface.wlanChannel() {
                let band: String
                switch wlanChannel.channelBand {
                case .bandUnknown:
                    band = "unknown"
                case .band2GHz:
                    band = "2.4GHz"
                case .band5GHz:
                    band = "5GHz"
                case .band6GHz:
                    band = "6GHz"
                @unknown default:
                    band = "unknown"
                }
                self.bandLabel = band
                self.channel = "\(wlanChannel.channelNumber) (\(band))"
            } else {
                self.bandLabel = ""
                self.channel = "N/A"
            }
        } else {
            // Interface not available – Wi‑Fi is off.
            self.ssid = "No interface"
            self.rssi = 0
            self.noise = 0
            self.channel = "N/A"
            self.bandLabel = ""
            self.txRate = 0
        }
    }

    // MARK: — Network Speed Monitoring

    private func startSpeedMonitoring() {
        // Initialize previous bytes
        let (bytesIn, bytesOut) = getNetworkBytes()
        previousBytesIn = bytesIn
        previousBytesOut = bytesOut

        speedTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) {
            [weak self] _ in
            self?.updateNetworkSpeed()
        }
    }

    private func updateNetworkSpeed() {
        let (bytesIn, bytesOut) = getNetworkBytes()
        let interval: Double = 2.0

        let deltaIn = bytesIn >= previousBytesIn ? bytesIn - previousBytesIn : 0
        let deltaOut = bytesOut >= previousBytesOut ? bytesOut - previousBytesOut : 0

        DispatchQueue.main.async {
            self.downloadSpeed = Double(deltaIn) / interval
            self.uploadSpeed = Double(deltaOut) / interval
        }

        previousBytesIn = bytesIn
        previousBytesOut = bytesOut
    }

    private func getNetworkBytes() -> (UInt64, UInt64) {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrs) == 0, let firstAddr = ifaddrs else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddrs) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ptr = firstAddr
        while true {
            let flags = Int32(ptr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0

            if isUp && !isLoopback {
                let addr = ptr.pointee.ifa_addr.pointee
                if addr.sa_family == UInt8(AF_LINK) {
                    if let data = ptr.pointee.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                        totalIn += UInt64(networkData.ifi_ibytes)
                        totalOut += UInt64(networkData.ifi_obytes)
                    }
                }
            }

            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }

        return (totalIn, totalOut)
    }

    // MARK: — Local IP

    private func updateLocalIP() {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrs) == 0, let firstAddr = ifaddrs else {
            localIP = "N/A"
            return
        }
        defer { freeifaddrs(ifaddrs) }

        var ip = "N/A"
        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(
                        interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count),
                        nil, 0, NI_NUMERICHOST
                    ) == 0 {
                        ip = String(cString: hostname)
                        break
                    }
                }
            }
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }

        DispatchQueue.main.async {
            self.localIP = ip
        }
    }

    // MARK: — Speed Formatting

    static func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        }
    }

    // MARK: — CLLocationManagerDelegate.

    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        updateWiFiInfo()
        updateLocalIP()
    }
}
