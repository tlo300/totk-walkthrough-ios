// ThemeManager.swift — Runtime theme state, persisted via @AppStorage.
import SwiftUI

final class ThemeManager: ObservableObject {
    @AppStorage("appTheme") var selectedTheme: AppTheme = .parchment {
        willSet { objectWillChange.send() }
    }
    @AppStorage("useHyliaSerif") var useHyliaSerif: Bool = true {
        willSet { objectWillChange.send() }
    }

    var colors: ThemeColors { selectedTheme.colors }

    func headingFont(size: CGFloat) -> Font {
        guard useHyliaSerif else {
            return .system(size: size, weight: .bold)
        }
        return .custom("HyliaSerif", size: size, relativeTo: .headline)
    }
}
