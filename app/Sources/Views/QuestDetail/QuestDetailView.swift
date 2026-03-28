// QuestDetailView.swift — Scrollable quest content: text, images, and checkpoint cards.
import SwiftUI

struct QuestDetailView: View {
    let quest: Quest
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore

    @State private var blocks: [ContentBlock] = []
    @State private var loadError: String?

    private var questFolder: String {
        quest.type == .main ? "quests" : "side-quests"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if let error = loadError {
                    Text("Could not load quest content: \(error)")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(quest.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadBlocks() }
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block {
        case .text(let markdown):
            if let attributed = try? AttributedString(markdown: markdown) {
                Text(attributed)
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                Text(markdown)
                    .font(.body)
                    .foregroundColor(.primary)
            }

        case .image(let filename):
            let imageName = "\(questFolder)/\(quest.slug)/\(filename)"
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

        case .checkpoint(let id, let label):
            CheckpointCard(id: id, label: label)
        }
    }

    private func loadBlocks() {
        do {
            blocks = try contentStore.contentBlocks(for: quest)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
