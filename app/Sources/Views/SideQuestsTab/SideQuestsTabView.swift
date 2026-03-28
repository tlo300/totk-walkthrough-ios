// SideQuestsTabView.swift — Browsable list of all side quests.
import SwiftUI

struct SideQuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore

    var body: some View {
        NavigationStack {
            List(contentStore.sideQuests) { quest in
                NavigationLink(destination: QuestDetailView(quest: quest)) {
                    Text(quest.title)
                }
            }
            .navigationTitle("Side Quests")
        }
    }
}
