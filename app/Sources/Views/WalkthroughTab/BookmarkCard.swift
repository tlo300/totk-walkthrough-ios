// BookmarkCard.swift — "Currently On" card showing the active quest bookmark.
import SwiftUI

struct BookmarkCard: View {
    let quests: [Quest]
    @EnvironmentObject private var progressStore: ProgressStore

    private var currentQuest: Quest? {
        guard let slug = progressStore.bookmark?.questSlug else { return nil }
        return quests.first { $0.slug == slug }
    }

    var body: some View {
        if let quest = currentQuest {
            VStack(alignment: .leading, spacing: 4) {
                Text("Currently On")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.yellow)
                    .textCase(.uppercase)
                Text(quest.title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.yellow.opacity(0.6), lineWidth: 1)
            )
        }
    }
}
