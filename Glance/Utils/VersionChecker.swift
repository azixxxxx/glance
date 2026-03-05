import Foundation

struct VersionChecker {
    private static let versionFileName = "current_glance_version"
    
    static var currentVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    static var versionFileURL: URL? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let glanceFolder = appSupport.appendingPathComponent("glance")
        return glanceFolder.appendingPathComponent(versionFileName)
    }
    
    static func isLatestVersion() -> Bool {
        guard let current = currentVersion,
              let url = versionFileURL,
              let savedVersion = try? String(contentsOf: url) else {
            return false
        }
        return savedVersion == current
    }
    
    static func updateVersionFile() {
        guard let current = currentVersion,
              let url = versionFileURL else { return }
        
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        try? current.write(to: url, atomically: true, encoding: .utf8)
    }
}
