//
//  ReeledApp.swift
//  Reeled
//
//  Created by シン・ジャスティン on 2026/03/16.
//

import SwiftUI

@main
struct ReeledApp: App {
    var body: some Scene {
        WindowGroup {
            ThemeRoot {
                ContentView()
            }
        }
    }
}

struct ThemeRoot<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .environment(\.theme, Theme(colorScheme: colorScheme))
    }
}
