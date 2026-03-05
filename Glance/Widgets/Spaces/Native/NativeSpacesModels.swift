import AppKit

struct NativeSpace: SpaceModel {
    var id: Int
    let spaceNumber: Int
    var isFocused: Bool
    var windows: [NativeWindow]

    enum CodingKeys: String, CodingKey {
        case id, spaceNumber, isFocused, windows
    }
}

struct NativeWindow: WindowModel, Codable {
    var id: Int
    var title: String
    var appName: String?
    var isFocused: Bool
    var appIcon: NSImage?

    enum CodingKeys: String, CodingKey {
        case id, title, appName, isFocused
    }
}
