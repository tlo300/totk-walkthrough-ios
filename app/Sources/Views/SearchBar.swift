// SearchBar.swift — Reusable themed search bar for list tabs.
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(themeManager.colors.secondaryText)
            TextField("Search", text: $text)
                .foregroundStyle(themeManager.colors.primaryText)
                .tint(themeManager.colors.accent)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(themeManager.colors.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(themeManager.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.colors.navBackground)
    }
}
