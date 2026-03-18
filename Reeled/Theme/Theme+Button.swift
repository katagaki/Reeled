import SwiftUI

extension Theme {

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
}
