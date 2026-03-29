// ProgressTabView.swift — Completion stats and progress reset.
import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingResetConfirm = false
    @State private var showingSettings = false

    private var completedMainCount: Int {
        contentStore.quests.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    private var completedSideCount: Int {
        contentStore.sideQuests.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    private var completedAdventureCount: Int {
        contentStore.adventures.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    private var completedShrineCount: Int {
        contentStore.shrines.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Completed", value: "\(completedMainCount) / \(contentStore.quests.count)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                    if contentStore.quests.count > 0 {
                        ProgressView(value: Double(completedMainCount), total: Double(contentStore.quests.count))
                            .tint(themeManager.colors.progressFill)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Main Quests").foregroundStyle(themeManager.colors.sectionLabel)
                }

                Section {
                    LabeledContent("Completed", value: "\(completedSideCount) / \(contentStore.sideQuests.count)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                    if contentStore.sideQuests.count > 0 {
                        ProgressView(value: Double(completedSideCount), total: Double(contentStore.sideQuests.count))
                            .tint(themeManager.colors.progressFill)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Side Quests").foregroundStyle(themeManager.colors.sectionLabel)
                }

                Section {
                    LabeledContent("Completed", value: "\(completedAdventureCount) / \(contentStore.adventures.count)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                    if contentStore.adventures.count > 0 {
                        ProgressView(value: Double(completedAdventureCount), total: Double(contentStore.adventures.count))
                            .tint(themeManager.colors.progressFill)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Adventures").foregroundStyle(themeManager.colors.sectionLabel)
                }

                Section {
                    LabeledContent("Completed", value: "\(completedShrineCount) / \(contentStore.shrines.count)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                    if contentStore.shrines.count > 0 {
                        ProgressView(value: Double(completedShrineCount), total: Double(contentStore.shrines.count))
                            .tint(themeManager.colors.progressFill)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Shrines").foregroundStyle(themeManager.colors.sectionLabel)
                }

                Section {
                    Button("Reset All Progress", role: .destructive) {
                        showingResetConfirm = true
                    }
                    .listRowBackground(themeManager.colors.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Progress")
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
            .confirmationDialog("Reset all progress?",
                                isPresented: $showingResetConfirm,
                                titleVisibility: .visible) {
                Button("Reset", role: .destructive) { progressStore.reset() }
            } message: {
                Text("This will clear all completed quests and your bookmark.")
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
