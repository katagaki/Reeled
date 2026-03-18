import SwiftUI

extension Theme {

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
