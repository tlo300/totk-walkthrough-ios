// SideQuestsTabView.swift — Browsable list of all side quests with completion tracking and regional sections.
import SwiftUI

struct SideQuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false
    @State private var searchText = ""

    private var completionFraction: Double {
        let total = contentStore.sideQuests.count
        guard total > 0 else { return 0 }
        let done = contentStore.sideQuests.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    private var filteredGrouped: [String: [Quest]] {
        let items = searchText.isEmpty
            ? contentStore.sideQuests
            : contentStore.sideQuests.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        return Dictionary(grouping: items) { $0.region ?? "Other" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Side Quests", showingSettings: $showingSettings)
                    .environmentObject(themeManager)
                SearchBar(text: $searchText)
                    .environmentObject(themeManager)

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Side Quest Progress")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(themeManager.colors.primaryText)
                                Spacer()
                                Text("\(Int(completionFraction * Double(contentStore.sideQuests.count))) / \(contentStore.sideQuests.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(themeManager.colors.accent)
                            }
                            ProgressView(value: completionFraction)
                                .tint(themeManager.colors.progressFill)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(themeManager.colors.cardBackground)
                    }

                    if !searchText.isEmpty && filteredGrouped.isEmpty {
                        Section {
                            Text("No results")
                                .foregroundStyle(themeManager.colors.secondaryText)
                                .listRowBackground(themeManager.colors.cardBackground)
                        }
                    }

                    ForEach(ModelConfig.regionOrder.filter { filteredGrouped[$0] != nil }, id: \.self) { region in
                        Section {
                            ForEach(filteredGrouped[region]!) { quest in
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
                        } header: {
                            Text(region)
                                .foregroundStyle(themeManager.colors.sectionLabel)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                .toolbar(.hidden, for: .navigationBar)
            }
            .background(themeManager.colors.background)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
