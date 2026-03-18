import SwiftUI

struct Theme {
    let colorScheme: ColorScheme

    var isLight: Bool { colorScheme == .light }

    // MARK: - Main background gradient

    var backgroundTop: Color {
        isLight ? Color(red: 0.92, green: 0.89, blue: 0.83)
                : Color(red: 0.16, green: 0.16, blue: 0.18)
    }
    var backgroundMid: Color {
        isLight ? Color(red: 0.90, green: 0.87, blue: 0.80)
                : Color(red: 0.10, green: 0.10, blue: 0.12)
    }
    var backgroundBottom: Color {
        isLight ? Color(red: 0.88, green: 0.85, blue: 0.78)
                : Color(red: 0.08, green: 0.08, blue: 0.10)
    }

    // MARK: - Top bar / header gradient

    var headerTop: Color {
        isLight ? Color(red: 0.95, green: 0.92, blue: 0.86)
                : Color(red: 0.24, green: 0.24, blue: 0.27)
    }
    var headerMid: Color {
        isLight ? Color(red: 0.92, green: 0.89, blue: 0.82)
                : Color(red: 0.18, green: 0.18, blue: 0.21)
    }
    var headerBottom: Color {
        isLight ? Color(red: 0.89, green: 0.86, blue: 0.79)
                : Color(red: 0.14, green: 0.14, blue: 0.16)
    }

    // MARK: - Header highlight overlay

    var headerHighlightTop: Color {
        isLight ? Color.white.opacity(0.5)
                : Color.white.opacity(0.08)
    }
    var headerHighlightMid: Color {
        isLight ? Color.white.opacity(0.15)
                : Color.white.opacity(0.02)
    }

    // MARK: - Header divider

    var headerDividerBottom: Color {
        isLight ? Color(red: 0.78, green: 0.75, blue: 0.68).opacity(0.5)
                : Color.black.opacity(0.4)
    }

    // MARK: - Shell colors (named from dark mode)

    var shellDark: Color {
        isLight ? Color(red: 0.82, green: 0.79, blue: 0.72)
                : Color(red: 0.12, green: 0.12, blue: 0.14)
    }
    var shellMid: Color {
        isLight ? Color(red: 0.85, green: 0.82, blue: 0.75)
                : Color(red: 0.22, green: 0.22, blue: 0.25)
    }
    var shellLight: Color {
        isLight ? Color(red: 0.88, green: 0.85, blue: 0.78)
                : Color(red: 0.32, green: 0.32, blue: 0.36)
    }
    var shellHighlight: Color {
        isLight ? Color(red: 0.72, green: 0.69, blue: 0.62)
                : Color(red: 0.45, green: 0.45, blue: 0.50)
    }
    var plasticBlue: Color {
        isLight ? Color(red: 0.70, green: 0.75, blue: 0.85)
                : Color(red: 0.15, green: 0.20, blue: 0.35)
    }
    var labelCream: Color {
        isLight ? Color(red: 0.35, green: 0.32, blue: 0.28)
                : Color(red: 0.92, green: 0.88, blue: 0.78)
    }

    // MARK: - Processing view

    var processingTint: Color {
        isLight ? Color(red: 0.25, green: 0.55, blue: 0.35)
                : Color(red: 0.4, green: 0.7, blue: 0.5)
    }

    // MARK: - Settings group

    var settingsGroupTitle: Color {
        isLight ? Color(red: 0.50, green: 0.48, blue: 0.42)
                : Color(red: 0.55, green: 0.55, blue: 0.60)
    }
    var settingsGroupBackground: Color {
        isLight ? Color(red: 0.94, green: 0.91, blue: 0.84)
                : Color(red: 0.14, green: 0.14, blue: 0.16)
    }
    var settingsGroupBorderTop: Color {
        isLight ? Color.white.opacity(0.5)
                : Color.white.opacity(0.06)
    }
    var settingsGroupBorderBottom: Color {
        isLight ? Color(red: 0.78, green: 0.75, blue: 0.68).opacity(0.3)
                : Color.black.opacity(0.2)
    }

    // MARK: - ProcessedImageView

    var processedImageBackground: Color {
        Color(red: 0.02, green: 0.02, blue: 0.03)
    }
    var processedImageOverlayTop: Color {
        isLight ? Color.white.opacity(0.12)
                : Color.white.opacity(0.04)
    }
    var processedImageOverlayBottom: Color {
        isLight ? Color.white.opacity(0.06)
                : Color.white.opacity(0.02)
    }
}

struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme(colorScheme: .dark)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
