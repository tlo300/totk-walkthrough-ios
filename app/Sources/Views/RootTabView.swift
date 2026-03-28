// RootTabView.swift — Root 4-tab navigation container.
import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView {
            WalkthroughTabView()
                .tabItem {
                    Label("Walkthrough", systemImage: "map")
                }
            QuestsTabView()
                .tabItem {
                    Label("Quests", systemImage: "sword")
                }
            SideQuestsTabView()
                .tabItem {
                    Label("Side Quests", systemImage: "star")
                }
            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
        }
        .tint(themeManager.colors.tabActive)
    }
}
