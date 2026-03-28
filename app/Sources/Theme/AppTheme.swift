// AppTheme.swift — Zelda theme definitions: colours and semantic values per theme.
import SwiftUI

enum AppTheme: String, CaseIterable {
    case parchment
    case zonaiDark
    case classicBlue

    var displayName: String {
        switch self {
        case .parchment:   return "Parchment & Gold"
        case .zonaiDark:   return "Zonai Dark"
        case .classicBlue: return "Classic Blue & Gold"
        }
    }

    var themeDescription: String {
        switch self {
        case .parchment:   return "Warm map scroll aesthetic"
        case .zonaiDark:   return "Ancient tech, glowing green"
        case .classicBlue: return "Timeless Zelda menu feel"
        }
    }

    var emoji: String {
        switch self {
        case .parchment:   return "📜"
        case .zonaiDark:   return "🌿"
        case .classicBlue: return "🏰"
        }
    }

    var colors: ThemeColors {
        switch self {
        case .parchment:
            return ThemeColors(
                background:        Color(hex: "f0e2c0"),
                cardBackground:    Color(hex: "e8d5a3"),
                cardBorder:        Color(hex: "c8a84b"),
                accent:            Color(hex: "c8a84b"),
                accentText:        Color(hex: "3d2200"),
                primaryText:       Color(hex: "3d2200"),
                secondaryText:     Color(hex: "8b6914"),
                sectionLabel:      Color(hex: "8b6914"),
                progressFill:      Color(hex: "5c3d11"),
                tabActive:         Color(hex: "5c3d11"),
                tabInactive:       Color(hex: "8b6914"),
                navBackground:     Color(hex: "e8d5a3"),
                navBorder:         Color(hex: "c8a84b"),
                checkpointDone:    Color(hex: "5c3d11"),
                checkpointPending: Color(hex: "c8a84b"),
                glow:              nil
            )
        case .zonaiDark:
            return ThemeColors(
                background:        Color(hex: "0d1a0f"),
                cardBackground:    Color(hex: "112214"),
                cardBorder:        Color(hex: "1f5a27"),
                accent:            Color(hex: "2d7a3a"),
                accentText:        Color(hex: "c8f0cc"),
                primaryText:       Color(hex: "c8f0cc"),
                secondaryText:     Color(hex: "3a8a4a"),
                sectionLabel:      Color(hex: "3a8a4a"),
                progressFill:      Color(hex: "2d7a3a"),
                tabActive:         Color(hex: "6eff7f"),
                tabInactive:       Color(hex: "3a8a4a"),
                navBackground:     Color(hex: "0f1f12"),
                navBorder:         Color(hex: "2d7a3a"),
                checkpointDone:    Color(hex: "6eff7f"),
                checkpointPending: Color(hex: "2d7a3a"),
                glow:              Color(hex: "2d7a3a")
            )
        case .classicBlue:
            return ThemeColors(
                background:        Color(hex: "111d36"),
                cardBackground:    Color(hex: "1a2744"),
                cardBorder:        Color(hex: "2a3d66"),
                accent:            Color(hex: "c8a84b"),
                accentText:        Color(hex: "0d1628"),
                primaryText:       Color(hex: "d0dcf0"),
                secondaryText:     Color(hex: "6a8acc"),
                sectionLabel:      Color(hex: "6a8acc"),
                progressFill:      Color(hex: "c8a84b"),
                tabActive:         Color(hex: "f0d060"),
                tabInactive:       Color(hex: "4a6aaa"),
                navBackground:     Color(hex: "1a2744"),
                navBorder:         Color(hex: "c8a84b"),
                checkpointDone:    Color(hex: "f0d060"),
                checkpointPending: Color(hex: "c8a84b"),
                glow:              nil
            )
        }
    }
}

struct ThemeColors {
    let background: Color
    let cardBackground: Color
    let cardBorder: Color
    let accent: Color
    let accentText: Color
    let primaryText: Color
    let secondaryText: Color
    let sectionLabel: Color
    let progressFill: Color
    let tabActive: Color
    let tabInactive: Color
    let navBackground: Color
    let navBorder: Color
    let checkpointDone: Color
    let checkpointPending: Color
    let glow: Color?
}

extension Color {
    init(hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
