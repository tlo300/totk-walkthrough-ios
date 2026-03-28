// SettingsSheet.swift — Theme picker and typography toggle, opened from any tab.
import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("App Theme") {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button {
                            themeManager.selectedTheme = theme
                        } label: {
                            HStack(spacing: 12) {
                                Text(theme.emoji)
                                    .font(.title2)
                                    .frame(width: 36, height: 36)
                                    .background(themeManager.colors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(themeManager.colors.cardBorder, lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(themeManager.colors.primaryText)
                                    Text(theme.themeDescription)
                                        .font(.caption)
                                        .foregroundStyle(themeManager.colors.secondaryText)
                                }

                                Spacer()

                                if themeManager.selectedTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(themeManager.colors.accent)
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                    }
                }

                Section("Typography") {
                    Toggle(isOn: $themeManager.useHyliaSerif) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hylia Serif headings")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(themeManager.colors.primaryText)
                            Text("Fan-made Zelda-style font")
                                .font(.caption)
                                .foregroundStyle(themeManager.colors.secondaryText)
                        }
                    }
                    .tint(themeManager.colors.accent)
                    .listRowBackground(themeManager.colors.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundStyle(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(themeManager.colors.accent)
                }
            }
            .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
