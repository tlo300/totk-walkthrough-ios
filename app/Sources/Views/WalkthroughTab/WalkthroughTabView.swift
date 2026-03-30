// WalkthroughTabView.swift — Linear quest walkthrough with progress and bookmark.
import SwiftUI

struct WalkthroughTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false
    @State private var searchText = ""

    private var completionFraction: Double {
        let total = contentStore.quests.count
        guard total > 0 else { return 0 }
        let done = contentStore.quests.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    private var filteredQuests: [Quest] {
        searchText.isEmpty
            ? contentStore.quests
            : contentStore.quests.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Walkthrough", showingSettings: $showingSettings)
                    .environmentObject(themeManager)
                SearchBar(text: $searchText)
                    .environmentObject(themeManager)

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Main Quest Progress")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(themeManager.colors.primaryText)
                                Spacer()
                                Text("\(Int(completionFraction * Double(contentStore.quests.count))) / \(contentStore.quests.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(themeManager.colors.accent)
                            }
                            ProgressView(value: completionFraction)
                                .tint(themeManager.colors.progressFill)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(themeManager.colors.cardBackground)

                        BookmarkCard(quests: contentStore.quests)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }

                    Section {
                        if !searchText.isEmpty && filteredQuests.isEmpty {
                            Text("No results")
                                .foregroundStyle(themeManager.colors.secondaryText)
                                .listRowBackground(themeManager.colors.cardBackground)
                        }
                        ForEach(filteredQuests) { quest in
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
                        Text("Quest Order")
                            .foregroundStyle(themeManager.colors.sectionLabel)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                .toolbar(.hidden, for: .navigationBar)
            }
            .background(themeManager.colors.background)
            .onAppear {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
