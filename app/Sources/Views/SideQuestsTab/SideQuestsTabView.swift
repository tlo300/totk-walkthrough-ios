// SideQuestsTabView.swift — Browsable list of all side quests.
import SwiftUI

struct SideQuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List(contentStore.sideQuests) { quest in
                NavigationLink(destination: QuestDetailView(quest: quest)) {
                    Text(quest.title)
                        .foregroundStyle(themeManager.colors.primaryText)
                }
                .listRowBackground(themeManager.colors.cardBackground)
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
