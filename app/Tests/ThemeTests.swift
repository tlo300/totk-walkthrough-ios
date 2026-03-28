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
