// BookmarkCard.swift — "Currently On" card showing the active quest bookmark.
import SwiftUI

struct BookmarkCard: View {
    let quests: [Quest]
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager

    private var currentQuest: Quest? {
        guard let slug = progressStore.bookmark?.questSlug else { return nil }
        return quests.first { $0.slug == slug }
    }

    var body: some View {
        if let quest = currentQuest {
            VStack(alignment: .leading, spacing: 4) {
                Text("Currently On")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(themeManager.colors.accent)
                    .textCase(.uppercase)
                Text(quest.title)
                    .font(.headline)
                    .foregroundStyle(themeManager.colors.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(themeManager.colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(themeManager.colors.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: themeManager.colors.glow ?? .clear,
                radius: 4, x: 0, y: 0
            )
        }
    }
}
