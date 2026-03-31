// RootTabView.swift — Root 6-tab navigation container.
import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView {
            WalkthroughTabView()
                .tabItem {
                    Label("Walkthrough", systemImage: "map")
                }
            AdventuresTabView()
                .tabItem {
                    Label("Adventures", systemImage: "figure.walk")
                }
            SideQuestsTabView()
                .tabItem {
                    Label("Side Quests", systemImage: "star")
                }
            ShrinesTabView()
                .tabItem {
                    Label("Shrines", systemImage: "diamond")
                }
            MapTabView()
                .tabItem {
                    Label("Map", systemImage: "mappin.and.ellipse")
                }
            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
        }
        .tint(themeManager.colors.tabActive)
    }
}
