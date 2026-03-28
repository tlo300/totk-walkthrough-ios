// WalkthroughTabView.swift — Linear quest walkthrough with progress and bookmark.
import SwiftUI

struct WalkthroughTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore

    private var completionFraction: Double {
        let total = contentStore.quests.count
        guard total > 0 else { return 0 }
        let done = contentStore.quests.filter { quest in
            isQuestComplete(quest)
        }.count
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
                            Spacer()
                            Text("\(Int(completionFraction * Double(contentStore.quests.count))) / \(contentStore.quests.count)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        ProgressView(value: completionFraction)
                            .tint(.green)
                    }
                    .padding(.vertical, 4)

                    BookmarkCard(quests: contentStore.quests)
                }

                Section("Quest Order") {
                    ForEach(contentStore.quests) { quest in
                        NavigationLink(destination: QuestDetailView(quest: quest)) {
                            HStack(spacing: 12) {
                                Image(systemName: isQuestComplete(quest) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isQuestComplete(quest) ? .green : .secondary)
                                Text(quest.title)
                                    .foregroundColor(isQuestComplete(quest) ? .secondary : .primary)
                                    .strikethrough(isQuestComplete(quest))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Walkthrough")
        }
    }
}
