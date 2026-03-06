import SwiftUI

struct AboutSettingsTab: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("Glance")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version \(appVersion) (\(buildNumber))")
                .foregroundStyle(.secondary)

            Text("Modern macOS status bar replacement")
                .foregroundStyle(.secondary)

            Divider()
                .frame(width: 200)

            Text("Made by azixxxxx")
                .font(.callout)

            HStack(spacing: 16) {
                Link("GitHub", destination: URL(string: "https://github.com/azixxxxx/glance")!)
            }
            .font(.callout)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
