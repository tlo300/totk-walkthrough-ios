// ThemeTests.swift — Unit tests for AppTheme colour values.
import XCTest
import SwiftUI
@testable import TOTKWalkthrough

final class ThemeTests: XCTestCase {

    func test_allThemes_haveDistinctRawValues() {
        let rawValues = AppTheme.allCases.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count, "Each AppTheme case must have a unique rawValue")
    }

    func test_zonaiDark_hasGlow() {
        XCTAssertNotNil(AppTheme.zonaiDark.colors.glow)
    }

    func test_parchment_hasNoGlow() {
        XCTAssertNil(AppTheme.parchment.colors.glow)
    }

    func test_classicBlue_hasNoGlow() {
        XCTAssertNil(AppTheme.classicBlue.colors.glow)
    }

    func test_allThemes_haveDisplayName() {
        for theme in AppTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty)
        }
    }

    func test_appTheme_rawValue_roundtrips() {
        for theme in AppTheme.allCases {
            XCTAssertEqual(AppTheme(rawValue: theme.rawValue), theme)
        }
    }
}

final class ThemeManagerTests: XCTestCase {

    func test_defaultTheme_isParchment() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.selectedTheme, .parchment)
    }

    func test_colors_matchesSelectedTheme() {
        let manager = ThemeManager()
        manager.selectedTheme = .zonaiDark
        XCTAssertNotNil(manager.colors.glow, "Zonai Dark must have a glow colour")
    }

    func test_headingFont_withSerif_returnsCustomFont() {
        let manager = ThemeManager()
        manager.useHyliaSerif = true
        let font = manager.headingFont(size: 20)
        XCTAssertNotNil(font)
    }

    func test_headingFont_withoutSerif_returnsSystemFont() {
        let manager = ThemeManager()
        manager.useHyliaSerif = false
        let font = manager.headingFont(size: 20)
        XCTAssertNotNil(font)
    }
}
