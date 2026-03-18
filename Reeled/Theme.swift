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

    // MARK: - Control bar

    var controlBarTop: Color {
        isLight ? Color(red: 0.93, green: 0.90, blue: 0.83)
                : Color(red: 0.20, green: 0.20, blue: 0.23)
    }
    var controlBarMid: Color {
        isLight ? Color(red: 0.89, green: 0.86, blue: 0.79)
                : Color(red: 0.14, green: 0.14, blue: 0.16)
    }
    var controlBarBottom: Color {
        isLight ? Color(red: 0.86, green: 0.83, blue: 0.76)
                : Color(red: 0.10, green: 0.10, blue: 0.12)
    }
    var controlBarHighlight: Color {
        isLight ? Color.white.opacity(0.3)
                : Color.white.opacity(0.05)
    }
    var controlBarTopEdge: Color {
        isLight ? Color.white.opacity(0.4)
                : Color.white.opacity(0.08)
    }
    var controlBarBottomEdge: Color {
        isLight ? Color(red: 0.78, green: 0.75, blue: 0.68).opacity(0.4)
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

    // MARK: - PlasticButton

    var buttonLabelColor: Color {
        isLight ? Color(red: 0.45, green: 0.43, blue: 0.38)
                : Color(red: 0.60, green: 0.60, blue: 0.65)
    }

    var buttonGradientTop: Color {
        isLight ? Color(red: 0.94, green: 0.91, blue: 0.84)
                : Color(red: 0.26, green: 0.26, blue: 0.30)
    }
    var buttonGradientMid: Color {
        isLight ? Color(red: 0.88, green: 0.85, blue: 0.78)
                : Color(red: 0.18, green: 0.18, blue: 0.21)
    }
    var buttonGradientBottom: Color {
        isLight ? Color(red: 0.84, green: 0.81, blue: 0.74)
                : Color(red: 0.14, green: 0.14, blue: 0.16)
    }
    var buttonPressedTop: Color {
        isLight ? Color(red: 0.84, green: 0.81, blue: 0.74)
                : Color(red: 0.12, green: 0.12, blue: 0.14)
    }
    var buttonPressedMid: Color {
        isLight ? Color(red: 0.86, green: 0.83, blue: 0.76)
                : Color(red: 0.15, green: 0.15, blue: 0.17)
    }
    var buttonPressedBottom: Color {
        isLight ? Color(red: 0.88, green: 0.85, blue: 0.78)
                : Color(red: 0.18, green: 0.18, blue: 0.20)
    }
    var buttonHighlightTop: Color {
        isLight ? Color.white.opacity(0.6)
                : Color.white.opacity(0.12)
    }
    var buttonHighlightMid: Color {
        isLight ? Color.white.opacity(0.15)
                : Color.white.opacity(0.03)
    }
    var buttonBorderTopNormal: Color {
        isLight ? Color.white.opacity(0.5)
                : Color.white.opacity(0.18)
    }
    var buttonBorderMidNormal: Color {
        isLight ? Color.white.opacity(0.2)
                : Color.white.opacity(0.06)
    }
    var buttonBorderBottomNormal1: Color {
        isLight ? Color(red: 0.78, green: 0.75, blue: 0.68).opacity(0.3)
                : Color.black.opacity(0.15)
    }
    var buttonBorderBottomNormal2: Color {
        isLight ? Color(red: 0.72, green: 0.69, blue: 0.62).opacity(0.4)
                : Color.black.opacity(0.25)
    }
    var buttonBorderTopPressed: Color {
        isLight ? Color(red: 0.72, green: 0.69, blue: 0.62).opacity(0.3)
                : Color.black.opacity(0.3)
    }
    var buttonBorderMidPressed: Color {
        isLight ? Color(red: 0.75, green: 0.72, blue: 0.65).opacity(0.2)
                : Color.black.opacity(0.2)
    }
    var buttonBorderBottomPressed1: Color {
        isLight ? Color.white.opacity(0.2)
                : Color.white.opacity(0.05)
    }
    var buttonBorderBottomPressed2: Color {
        isLight ? Color.white.opacity(0.35)
                : Color.white.opacity(0.10)
    }
    var buttonShadow: Color {
        isLight ? Color(red: 0.60, green: 0.57, blue: 0.50).opacity(0.3)
                : Color.black.opacity(0.4)
    }
    var buttonTopShadow: Color {
        isLight ? Color.white.opacity(0.3)
                : Color.white.opacity(0.05)
    }

    // MARK: - VintageSlider

    var sliderLabel: Color {
        isLight ? Color(red: 0.50, green: 0.48, blue: 0.42)
                : Color(red: 0.70, green: 0.68, blue: 0.62)
    }
    var sliderTrack: Color {
        isLight ? Color(red: 0.78, green: 0.75, blue: 0.68)
                : Color(red: 0.06, green: 0.06, blue: 0.07)
    }
    var sliderTrackBorderTop: Color {
        isLight ? Color(red: 0.70, green: 0.67, blue: 0.60).opacity(0.5)
                : Color.black.opacity(0.5)
    }
    var sliderTrackBorderBottom: Color {
        isLight ? Color.white.opacity(0.3)
                : Color.white.opacity(0.04)
    }
    var sliderAccent: Color {
        isLight ? Color(red: 0.62, green: 0.58, blue: 0.48)
                : Color(red: 0.88, green: 0.84, blue: 0.74)
    }
    var sliderThumbTop: Color {
        isLight ? Color(red: 0.96, green: 0.93, blue: 0.86)
                : Color(red: 0.32, green: 0.32, blue: 0.36)
    }
    var sliderThumbMid: Color {
        isLight ? Color(red: 0.90, green: 0.87, blue: 0.80)
                : Color(red: 0.20, green: 0.20, blue: 0.23)
    }
    var sliderThumbBottom: Color {
        isLight ? Color(red: 0.86, green: 0.83, blue: 0.76)
                : Color(red: 0.15, green: 0.15, blue: 0.17)
    }
    var sliderThumbPressedTop: Color {
        isLight ? Color(red: 0.88, green: 0.85, blue: 0.78)
                : Color(red: 0.22, green: 0.22, blue: 0.26)
    }
    var sliderThumbPressedMid: Color {
        isLight ? Color(red: 0.84, green: 0.81, blue: 0.74)
                : Color(red: 0.16, green: 0.16, blue: 0.19)
    }
    var sliderThumbPressedBottom: Color {
        isLight ? Color(red: 0.82, green: 0.79, blue: 0.72)
                : Color(red: 0.12, green: 0.12, blue: 0.14)
    }
    var sliderThumbDot: Color {
        isLight ? Color(red: 0.60, green: 0.57, blue: 0.50)
                : Color.black
    }
    var sliderThumbBorderTopNormal: Color {
        isLight ? Color.white.opacity(0.6)
                : Color.white.opacity(0.20)
    }
    var sliderThumbBorderMidNormal: Color {
        isLight ? Color.white.opacity(0.2)
                : Color.white.opacity(0.05)
    }
    var sliderThumbBorderBottom1Normal: Color {
        isLight ? Color(red: 0.72, green: 0.69, blue: 0.62).opacity(0.3)
                : Color.black.opacity(0.15)
    }
    var sliderThumbBorderBottom2Normal: Color {
        isLight ? Color(red: 0.68, green: 0.65, blue: 0.58).opacity(0.4)
                : Color.black.opacity(0.25)
    }
    var sliderThumbBorderTopPressed: Color {
        isLight ? Color(red: 0.68, green: 0.65, blue: 0.58).opacity(0.3)
                : Color.black.opacity(0.25)
    }
    var sliderThumbBorderMidPressed: Color {
        isLight ? Color(red: 0.72, green: 0.69, blue: 0.62).opacity(0.2)
                : Color.black.opacity(0.15)
    }
    var sliderThumbBorderBottom1Pressed: Color {
        isLight ? Color.white.opacity(0.15)
                : Color.white.opacity(0.04)
    }
    var sliderThumbBorderBottom2Pressed: Color {
        isLight ? Color.white.opacity(0.3)
                : Color.white.opacity(0.08)
    }
    var sliderThumbShadow: Color {
        isLight ? Color(red: 0.60, green: 0.57, blue: 0.50).opacity(0.3)
                : Color.black.opacity(0.4)
    }

}

// MARK: - EmptyState VHS tape & reel colors
extension Theme {
    // In light mode: white/clean shell, but tape area stays dark

    var tapeShellTop: Color {
        isLight ? Color(red: 0.96, green: 0.95, blue: 0.93)
                : Color(red: 0.20, green: 0.20, blue: 0.22)
    }
    var tapeShellMid: Color {
        isLight ? Color(red: 0.93, green: 0.92, blue: 0.90)
                : Color(red: 0.14, green: 0.14, blue: 0.16)
    }
    var tapeShellBottom: Color {
        isLight ? Color(red: 0.90, green: 0.89, blue: 0.87)
                : Color(red: 0.11, green: 0.11, blue: 0.13)
    }
    var tapeShellHighlightTop: Color {
        isLight ? Color.white.opacity(0.7)
                : Color.white.opacity(0.08)
    }
    var tapeShellHighlightMid: Color {
        isLight ? Color.white.opacity(0.2)
                : Color.white.opacity(0.01)
    }
    var tapeShellBorderTop: Color {
        isLight ? Color.white.opacity(0.8)
                : Color.white.opacity(0.12)
    }
    var tapeShellBorderMid: Color {
        isLight ? Color.white.opacity(0.3)
                : Color.white.opacity(0.04)
    }
    var tapeShellBorderBottom1: Color {
        isLight ? Color(red: 0.82, green: 0.80, blue: 0.78).opacity(0.4)
                : Color.black.opacity(0.2)
    }
    var tapeShellBorderBottom2: Color {
        isLight ? Color(red: 0.78, green: 0.76, blue: 0.74).opacity(0.5)
                : Color.black.opacity(0.3)
    }
    var tapeShellShadow: Color {
        isLight ? Color(red: 0.70, green: 0.67, blue: 0.60).opacity(0.35)
                : Color.black.opacity(0.5)
    }
    var tapeSmallText: Color {
        isLight ? Color(red: 0.70, green: 0.68, blue: 0.65)
                : Color(red: 0.32, green: 0.32, blue: 0.35)
    }
    var tapeGrooveLine: Color {
        isLight ? Color(red: 0.82, green: 0.80, blue: 0.78).opacity(0.5)
                : Color.black.opacity(0.35)
    }
    var tapeGrooveHighlight: Color {
        isLight ? Color.white.opacity(0.5)
                : Color.white.opacity(0.04)
    }
    var tapeLabelTop: Color {
        // Label stays cream in both modes
        Color(red: 0.94, green: 0.90, blue: 0.80)
    }
    var tapeLabelBottom: Color {
        Color(red: 0.88, green: 0.84, blue: 0.74)
    }
    var tapeLabelTitle: Color {
        Color(red: 0.2, green: 0.2, blue: 0.25)
    }
    var tapeLabelSubtitle: Color {
        Color(red: 0.45, green: 0.43, blue: 0.40)
    }
    var tapeLabelLine: Color {
        Color(red: 0.75, green: 0.72, blue: 0.65)
    }
    var tapeLabelBorder: Color {
        Color(red: 0.7, green: 0.67, blue: 0.60)
    }
    // Tape window/reels stay dark in both modes
    var tapeWindowBackground: Color {
        Color(red: 0.05, green: 0.05, blue: 0.06)
    }
    var tapeWindowBorderTop: Color {
        Color.black.opacity(0.5)
    }
    var tapeWindowBorderBottom: Color {
        Color.white.opacity(0.05)
    }
    var tapePinFill: Color {
        Color(red: 0.08, green: 0.08, blue: 0.09)
    }
    var tapePinBorder: Color {
        Color(red: 0.18, green: 0.18, blue: 0.20)
    }
    var emptyStateText: Color {
        isLight ? Color(red: 0.55, green: 0.52, blue: 0.46)
                : Color(red: 0.50, green: 0.50, blue: 0.55)
    }

    // MARK: - TapeReelView
    // Reels stay dark in both modes

    var reelTape1: Color {
        Color(red: 0.08, green: 0.06, blue: 0.04)
    }
    var reelTape2: Color {
        Color(red: 0.12, green: 0.10, blue: 0.08)
    }
    var reelTape3: Color {
        Color(red: 0.06, green: 0.05, blue: 0.04)
    }
    var reelTapeBorder: Color {
        Color(red: 0.15, green: 0.13, blue: 0.10)
    }
    var reelHubFill: Color {
        Color(red: 0.20, green: 0.20, blue: 0.22)
    }
    var reelHubBorder: Color {
        Color(red: 0.28, green: 0.28, blue: 0.30)
    }
    var reelSpoke: Color {
        Color(red: 0.30, green: 0.30, blue: 0.32)
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
