// SideQuestsTabView.swift — Browsable list of all side quests with completion tracking.
import SwiftUI

struct SideQuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(contentStore.sideQuests) { quest in
                    HStack(spacing: 12) {
                        Button {
                            progressStore.toggleQuest(quest.slug)
                        } label: {
                            Image(systemName: progressStore.isQuestComplete(quest.slug) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: QuestDetailView(quest: quest)) {
                            Text(quest.title)
                                .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                .strikethrough(progressStore.isQuestComplete(quest.slug))
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            progressStore.toggleQuest(quest.slug)
                        } label: {
                            Label(
                                progressStore.isQuestComplete(quest.slug) ? "Undo" : "Done",
                                systemImage: progressStore.isQuestComplete(quest.slug) ? "arrow.uturn.backward" : "checkmark"
                            )
                        }
                        .tint(progressStore.isQuestComplete(quest.slug) ? .gray : .green)
                    }
                    .listRowBackground(themeManager.colors.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Side Quests")
                        .font(themeManager.headingFont(size: 20))
                        .foregroundStyle(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(themeManager.colors.accent)
                    }
                }
            }
            .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
