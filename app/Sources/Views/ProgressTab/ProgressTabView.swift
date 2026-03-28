// ProgressTabView.swift — Completion stats and progress reset.
import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingResetConfirm = false
    @State private var showingSettings = false

    private var completedCount: Int {
        progressStore.completedCheckpoints.count
    }

    private var totalCheckpoints: Int {
        contentStore.quests.compactMap { quest in
            try? contentStore.contentBlocks(for: quest)
        }
        .flatMap { $0 }
        .filter { if case .checkpoint = $0 { return true }; return false }
        .count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Total Quests", value: "\(contentStore.quests.count)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                } header: {
                    Text("Main Quests").foregroundStyle(themeManager.colors.sectionLabel)
                }

                Section {
                    LabeledContent("Total Side Quests", value: "\(contentStore.sideQuests.count)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                } header: {
                    Text("Side Quests").foregroundStyle(themeManager.colors.sectionLabel)
                }

                Section {
                    LabeledContent("Completed", value: "\(completedCount) / \(totalCheckpoints)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                    if totalCheckpoints > 0 {
                        ProgressView(value: Double(completedCount), total: Double(totalCheckpoints))
                            .tint(themeManager.colors.progressFill)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Checkpoints").foregroundStyle(themeManager.colors.sectionLabel)
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
                Text("This will clear all completed checkpoints and your bookmark.")
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
