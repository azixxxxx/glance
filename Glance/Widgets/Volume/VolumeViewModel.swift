import AudioToolbox
import Foundation

final class VolumeViewModel: ObservableObject {
    @Published var volume: Float = 0.0
    @Published var isMuted: Bool = false
    @Published var outputDeviceName: String = ""

    private var timer: Timer?

    init() {
        updateVolume()
        updateOutputDeviceName()
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
            [weak self] _ in
            self?.updateVolume()
            self?.updateOutputDeviceName()
        }
    }

    func updateVolume() {
        guard let deviceID = getDefaultOutputDevice() else { return }

        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            deviceID, &address, 0, nil, &size, &volume)
        if status == noErr {
            DispatchQueue.main.async {
                self.volume = volume
            }
        }

        var mute: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let muteStatus = AudioObjectGetPropertyData(
            deviceID, &muteAddress, 0, nil, &muteSize, &mute)
        if muteStatus == noErr {
            DispatchQueue.main.async {
                self.isMuted = mute != 0
            }
        }
    }

    func setVolume(_ newVolume: Float) {
        guard let deviceID = getDefaultOutputDevice() else { return }

        var vol = max(0, min(1, newVolume))
        let size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &vol)
        DispatchQueue.main.async {
            self.volume = vol
        }
    }

    func toggleMute() {
        guard let deviceID = getDefaultOutputDevice() else { return }

        var mute: UInt32 = isMuted ? 0 : 1
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &mute)
        DispatchQueue.main.async {
            self.isMuted = !self.isMuted
        }
    }

    func adjustVolume(by delta: Float) {
        setVolume(volume + delta)
    }

    private func getDefaultOutputDevice() -> AudioObjectID? {
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )

        return status == noErr ? deviceID : nil
    }

    var volumeIconName: String {
        if isMuted || volume == 0 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }

    var volumePercent: Int {
        Int(round(volume * 100))
    }

    func updateOutputDeviceName() {
        guard let deviceID = getDefaultOutputDevice() else { return }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &size) == noErr else { return }

        var name: Unmanaged<CFString>?
        let status = withUnsafeMutablePointer(to: &name) { ptr in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
        }
        if status == noErr, let cfName = name?.takeUnretainedValue() {
            let deviceName = cfName as String
            DispatchQueue.main.async {
                self.outputDeviceName = deviceName
            }
        }
    }

    var outputDeviceIcon: String {
        let lower = outputDeviceName.lowercased()
        if lower.contains("airpods") {
            return "airpodspro"
        } else if lower.contains("headphone") || lower.contains("headset") {
            return "headphones"
        } else if lower.contains("bluetooth") || lower.contains("beats") {
            return "hifispeaker"
        } else if lower.contains("display") || lower.contains("hdmi") || lower.contains("tv") {
            return "tv"
        } else {
            return "hifispeaker.2"
        }
    }
}
