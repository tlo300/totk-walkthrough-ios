// QuestsTabView.swift — Browsable list of all main quests.
import SwiftUI

struct QuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore

    var body: some View {
        NavigationStack {
            List(contentStore.quests) { quest in
                NavigationLink(destination: QuestDetailView(quest: quest)) {
                    Text(quest.title)
                }
            }
            .navigationTitle("Quests")
        }
    }
}
