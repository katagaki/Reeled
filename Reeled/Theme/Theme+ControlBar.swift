import SwiftUI

extension Theme {

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
}
