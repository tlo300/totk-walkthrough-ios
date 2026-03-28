// WalkthroughTabView.swift — Linear quest walkthrough with progress and bookmark.
import SwiftUI

struct WalkthroughTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    private var completionFraction: Double {
        let total = contentStore.quests.count
        guard total > 0 else { return 0 }
        let done = contentStore.quests.filter { isQuestComplete($0) }.count
        return Double(done) / Double(total)
    }

    private func isQuestComplete(_ quest: Quest) -> Bool {
        guard let blocks = try? contentStore.contentBlocks(for: quest) else { return false }
        let checkpointIDs = blocks.compactMap { block -> String? in
            if case .checkpoint(let id, _) = block { return id }
            return nil
        }
        return !checkpointIDs.isEmpty && checkpointIDs.allSatisfy { progressStore.isCheckpointComplete($0) }
    }

    var body: some View {
        NavigationStack {
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
                    ForEach(contentStore.quests) { quest in
                        NavigationLink(destination: QuestDetailView(quest: quest)) {
                            HStack(spacing: 12) {
                                Image(systemName: isQuestComplete(quest) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isQuestComplete(quest) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                                Text(quest.title)
                                    .foregroundStyle(isQuestComplete(quest) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                    .strikethrough(isQuestComplete(quest))
                            }
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Walkthrough")
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
