// MapTabView.swift — Map tab with layer picker, zoomable map, and pin navigation.
import SwiftUI

struct MapTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var mapStore: MapStore
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedLayer: MapLayer = .surface
    @State private var selectedShrine: Quest?
    @State private var selectedTower: MapPin?
    @State private var showingSettings = false

    private var completedSlugs: Set<String> {
        progressStore.completedQuests.union(progressStore.completedTowers)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Map", showingSettings: $showingSettings)
                    .environmentObject(themeManager)

                Picker("Layer", selection: $selectedLayer) {
                    Text("Surface").tag(MapLayer.surface)
                    Text("Sky").tag(MapLayer.sky)
                    Text("Depths").tag(MapLayer.depths)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(themeManager.colors.background)

                MapScrollView(
                    pins: mapStore.pins(for: selectedLayer),
                    completedSlugs: completedSlugs,
                    contentURL: contentStore.contentURL,
                    onShrineTap: { slug in
                        selectedShrine = contentStore.shrines.first { $0.slug == slug }
                    },
                    onTowerTap: { pin in
                        selectedTower = pin
                    }
                )
            }
            .background(themeManager.colors.background)
            .navigationDestination(item: $selectedShrine) { shrine in
                QuestDetailView(quest: shrine)
            }
            .sheet(item: $selectedTower) { tower in
                TowerPopover(pin: tower)
                    .environmentObject(progressStore)
                    .environmentObject(themeManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
