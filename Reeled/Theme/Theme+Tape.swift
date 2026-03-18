import SwiftUI

extension Theme {

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
}
