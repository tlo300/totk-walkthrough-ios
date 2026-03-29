// TabHeaderView.swift — Compact custom header replacing the system navigation bar on list tabs.
import SwiftUI

struct TabHeaderView: View {
    let title: String
    @Binding var showingSettings: Bool
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            Text(title)
                .font(themeManager.headingFont(size: 20))
                .foregroundStyle(themeManager.colors.accent)
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(themeManager.colors.accent)
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 8)
        .background(themeManager.colors.navBackground)
    }
}
