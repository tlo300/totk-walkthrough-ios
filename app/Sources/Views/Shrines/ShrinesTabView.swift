// ShrinesTabView.swift — Shrine list with completion tracking and detail navigation.
import SwiftUI

struct ShrinesTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    private var completionFraction: Double {
        let total = contentStore.shrines.count
        guard total > 0 else { return 0 }
        let done = contentStore.shrines.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Shrine Progress")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(themeManager.colors.primaryText)
                            Spacer()
                            Text("\(Int(completionFraction * Double(contentStore.shrines.count))) / \(contentStore.shrines.count)")
                                .font(.subheadline)
                                .foregroundStyle(themeManager.colors.accent)
                        }
                        ProgressView(value: completionFraction)
                            .tint(themeManager.colors.progressFill)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(themeManager.colors.cardBackground)
                }

                Section {
                    ForEach(contentStore.shrines) { shrine in
                        HStack(spacing: 12) {
                            Button {
                                progressStore.toggleQuest(shrine.slug)
                            } label: {
                                Image(systemName: progressStore.isQuestComplete(shrine.slug) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(progressStore.isQuestComplete(shrine.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: QuestDetailView(quest: shrine)) {
                                Text(shrine.title)
                                    .foregroundStyle(progressStore.isQuestComplete(shrine.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                    .strikethrough(progressStore.isQuestComplete(shrine.slug))
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                progressStore.toggleQuest(shrine.slug)
                            } label: {
                                Label(
                                    progressStore.isQuestComplete(shrine.slug) ? "Undo" : "Done",
                                    systemImage: progressStore.isQuestComplete(shrine.slug) ? "arrow.uturn.backward" : "checkmark"
                                )
                            }
                            .tint(progressStore.isQuestComplete(shrine.slug) ? .gray : .green)
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Shrine Order")
                        .foregroundStyle(themeManager.colors.sectionLabel)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shrines")
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
