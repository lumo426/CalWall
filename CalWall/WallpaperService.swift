import AppKit
import Foundation

final class WallpaperService {
    func updateWallpaper(
        events: [CalendarEvent],
        perspective: CalendarPerspective,
        customText: String,
        themeFamily: WallpaperThemeFamily,
        blueVariant: BlueThemeVariant
    ) throws -> URL {
        let screens = NSScreen.screens.isEmpty ? [NSScreen.main].compactMap { $0 } : NSScreen.screens
        guard let firstScreen = screens.first else {
            throw WallpaperError.noScreen
        }

        var firstURL: URL?

        for screen in screens {
            let scale = screen.backingScaleFactor
            let pixelSize = CGSize(
                width: max(1920, screen.frame.width * scale),
                height: max(1080, screen.frame.height * scale)
            )

            let imageURL = try WallpaperRenderer.render(
                date: Date(),
                events: events,
                perspective: perspective,
                customText: customText,
                canvasSize: pixelSize,
                screenName: screen.localizedName,
                themeFamily: themeFamily,
                blueVariant: blueVariant
            )

            var options = NSWorkspace.shared.desktopImageOptions(for: screen) ?? [:]
            options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
            try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen, options: options)

            if screen == firstScreen {
                firstURL = imageURL
            }
        }

        return firstURL ?? URL(fileURLWithPath: "")
    }
}

enum WallpaperError: LocalizedError {
    case noScreen

    var errorDescription: String? {
        switch self {
        case .noScreen:
            return "No display was detected."
        }
    }
}
