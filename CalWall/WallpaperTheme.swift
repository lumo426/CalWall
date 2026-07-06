import AppKit
import Foundation

enum WallpaperThemeFamily: String, CaseIterable, Identifiable, Codable {
    case light
    case dark
    case blue

    var id: String { rawValue }

    var supportsBlueVariant: Bool { self == .blue }
}

enum BlueThemeVariant: String, CaseIterable, Identifiable, Codable {
    case light
    case dark

    var id: String { rawValue }
}

struct ThemePalette {
    let background: NSColor
    let backgroundSubtle: NSColor
    let border: NSColor
    let textPrimary: NSColor
    let textSecondary: NSColor
    let textMuted: NSColor
    let todayHighlight: NSColor
    let todayText: NSColor
    let eventColors: [(bg: NSColor, fg: NSColor)]

    static func resolve(family: WallpaperThemeFamily, blueVariant: BlueThemeVariant) -> ThemePalette {
        switch family {
        case .light: return .light
        case .dark: return .dark
        case .blue: return blueVariant == .light ? .blueLight : .blueDark
        }
    }

    static let light = ThemePalette(
        background: NSColor.white,
        backgroundSubtle: NSColor(calibratedRed: 0.976, green: 0.980, blue: 0.984, alpha: 1),
        border: NSColor(calibratedRed: 0.898, green: 0.906, blue: 0.922, alpha: 1),
        textPrimary: NSColor(calibratedRed: 0.067, green: 0.094, blue: 0.153, alpha: 1),
        textSecondary: NSColor(calibratedRed: 0.420, green: 0.447, blue: 0.502, alpha: 1),
        textMuted: NSColor(calibratedRed: 0.612, green: 0.639, blue: 0.686, alpha: 1),
        todayHighlight: NSColor(calibratedRed: 0.067, green: 0.094, blue: 0.153, alpha: 1),
        todayText: NSColor.white,
        eventColors: sharedEventColors
    )

    static let dark = ThemePalette(
        background: NSColor(calibratedRed: 0.059, green: 0.067, blue: 0.090, alpha: 1),
        backgroundSubtle: NSColor(calibratedRed: 0.118, green: 0.137, blue: 0.180, alpha: 1),
        border: NSColor(calibratedRed: 0.216, green: 0.255, blue: 0.318, alpha: 1),
        textPrimary: NSColor(calibratedRed: 0.945, green: 0.961, blue: 0.976, alpha: 1),
        textSecondary: NSColor(calibratedRed: 0.580, green: 0.639, blue: 0.722, alpha: 1),
        textMuted: NSColor(calibratedRed: 0.392, green: 0.455, blue: 0.545, alpha: 1),
        todayHighlight: NSColor(calibratedRed: 0.945, green: 0.961, blue: 0.976, alpha: 1),
        todayText: NSColor(calibratedRed: 0.059, green: 0.067, blue: 0.090, alpha: 1),
        eventColors: darkEventColors
    )

    static let blueLight = ThemePalette(
        background: NSColor(calibratedRed: 0.937, green: 0.965, blue: 1.000, alpha: 1),
        backgroundSubtle: NSColor(calibratedRed: 0.859, green: 0.918, blue: 0.996, alpha: 1),
        border: NSColor(calibratedRed: 0.749, green: 0.859, blue: 0.996, alpha: 1),
        textPrimary: NSColor(calibratedRed: 0.118, green: 0.251, blue: 0.686, alpha: 1),
        textSecondary: NSColor(calibratedRed: 0.231, green: 0.510, blue: 0.965, alpha: 1),
        textMuted: NSColor(calibratedRed: 0.376, green: 0.647, blue: 0.980, alpha: 1),
        todayHighlight: NSColor(calibratedRed: 0.145, green: 0.388, blue: 0.922, alpha: 1),
        todayText: NSColor.white,
        eventColors: blueLightEventColors
    )

    static let blueDark = ThemePalette(
        background: NSColor(calibratedRed: 0.047, green: 0.098, blue: 0.196, alpha: 1),
        backgroundSubtle: NSColor(calibratedRed: 0.075, green: 0.165, blue: 0.345, alpha: 1),
        border: NSColor(calibratedRed: 0.145, green: 0.388, blue: 0.922, alpha: 0.45),
        textPrimary: NSColor(calibratedRed: 0.859, green: 0.918, blue: 0.996, alpha: 1),
        textSecondary: NSColor(calibratedRed: 0.576, green: 0.773, blue: 0.992, alpha: 1),
        textMuted: NSColor(calibratedRed: 0.376, green: 0.647, blue: 0.980, alpha: 1),
        todayHighlight: NSColor(calibratedRed: 0.231, green: 0.510, blue: 0.965, alpha: 1),
        todayText: NSColor.white,
        eventColors: blueDarkEventColors
    )

    private static let sharedEventColors: [(bg: NSColor, fg: NSColor)] = [
        (NSColor(calibratedRed: 0.992, green: 0.878, blue: 0.925, alpha: 1), NSColor(calibratedRed: 0.757, green: 0.063, blue: 0.357, alpha: 1)),
        (NSColor(calibratedRed: 0.859, green: 0.918, blue: 0.996, alpha: 1), NSColor(calibratedRed: 0.118, green: 0.251, blue: 0.686, alpha: 1)),
        (NSColor(calibratedRed: 0.863, green: 0.988, blue: 0.906, alpha: 1), NSColor(calibratedRed: 0.086, green: 0.396, blue: 0.204, alpha: 1)),
        (NSColor(calibratedRed: 0.996, green: 0.902, blue: 0.808, alpha: 1), NSColor(calibratedRed: 0.761, green: 0.255, blue: 0.047, alpha: 1)),
        (NSColor(calibratedRed: 0.933, green: 0.878, blue: 0.996, alpha: 1), NSColor(calibratedRed: 0.486, green: 0.227, blue: 0.929, alpha: 1)),
    ]

    private static let darkEventColors: [(bg: NSColor, fg: NSColor)] = [
        (NSColor(calibratedRed: 0.345, green: 0.114, blue: 0.220, alpha: 1), NSColor(calibratedRed: 0.992, green: 0.878, blue: 0.925, alpha: 1)),
        (NSColor(calibratedRed: 0.118, green: 0.251, blue: 0.686, alpha: 0.55), NSColor(calibratedRed: 0.859, green: 0.918, blue: 0.996, alpha: 1)),
        (NSColor(calibratedRed: 0.086, green: 0.396, blue: 0.204, alpha: 0.45), NSColor(calibratedRed: 0.863, green: 0.988, blue: 0.906, alpha: 1)),
        (NSColor(calibratedRed: 0.573, green: 0.251, blue: 0.055, alpha: 0.55), NSColor(calibratedRed: 0.996, green: 0.902, blue: 0.808, alpha: 1)),
        (NSColor(calibratedRed: 0.345, green: 0.165, blue: 0.573, alpha: 0.55), NSColor(calibratedRed: 0.933, green: 0.878, blue: 0.996, alpha: 1)),
    ]

    private static let blueLightEventColors: [(bg: NSColor, fg: NSColor)] = [
        (NSColor(calibratedRed: 0.992, green: 0.878, blue: 0.925, alpha: 1), NSColor(calibratedRed: 0.757, green: 0.063, blue: 0.357, alpha: 1)),
        (NSColor(calibratedRed: 0.749, green: 0.859, blue: 0.996, alpha: 1), NSColor(calibratedRed: 0.118, green: 0.251, blue: 0.686, alpha: 1)),
        (NSColor(calibratedRed: 0.863, green: 0.988, blue: 0.906, alpha: 1), NSColor(calibratedRed: 0.086, green: 0.396, blue: 0.204, alpha: 1)),
        (NSColor(calibratedRed: 0.996, green: 0.902, blue: 0.808, alpha: 1), NSColor(calibratedRed: 0.761, green: 0.255, blue: 0.047, alpha: 1)),
        (NSColor(calibratedRed: 0.576, green: 0.773, blue: 0.992, alpha: 0.65), NSColor(calibratedRed: 0.118, green: 0.251, blue: 0.686, alpha: 1)),
    ]

    private static let blueDarkEventColors: [(bg: NSColor, fg: NSColor)] = [
        (NSColor(calibratedRed: 0.345, green: 0.114, blue: 0.220, alpha: 0.85), NSColor(calibratedRed: 0.992, green: 0.878, blue: 0.925, alpha: 1)),
        (NSColor(calibratedRed: 0.145, green: 0.388, blue: 0.922, alpha: 0.55), NSColor(calibratedRed: 0.859, green: 0.918, blue: 0.996, alpha: 1)),
        (NSColor(calibratedRed: 0.086, green: 0.396, blue: 0.204, alpha: 0.45), NSColor(calibratedRed: 0.863, green: 0.988, blue: 0.906, alpha: 1)),
        (NSColor(calibratedRed: 0.573, green: 0.251, blue: 0.055, alpha: 0.55), NSColor(calibratedRed: 0.996, green: 0.902, blue: 0.808, alpha: 1)),
        (NSColor(calibratedRed: 0.075, green: 0.165, blue: 0.345, alpha: 1), NSColor(calibratedRed: 0.576, green: 0.773, blue: 0.992, alpha: 1)),
    ]
}

final class WallpaperThemeStore {
    private let defaults = UserDefaults.standard
    private let familyKey = "CalWall.ThemeFamily"
    private let blueVariantKey = "CalWall.BlueThemeVariant"

    var themeFamily: WallpaperThemeFamily {
        get {
            guard let raw = defaults.string(forKey: familyKey),
                  let value = WallpaperThemeFamily(rawValue: raw) else { return .light }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: familyKey) }
    }

    var blueVariant: BlueThemeVariant {
        get {
            guard let raw = defaults.string(forKey: blueVariantKey),
                  let value = BlueThemeVariant(rawValue: raw) else { return .light }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: blueVariantKey) }
    }
}
