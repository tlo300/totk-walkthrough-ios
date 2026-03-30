// QuestDetailView.swift — Scrollable quest content: text, images, and checkpoint cards.
import SwiftUI

struct QuestDetailView: View {
    let quest: Quest
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var blocks: [ContentBlock] = []
    @State private var loadError: String?
    @State private var selectedImage: UIImage?

    private var questContentURL: URL {
        let folder: String
        switch quest.type {
        case .main: folder = "quests"
        case .side: folder = "side-quests"
        case .shrine: folder = "shrines"
        case .adventure: folder = "adventures"
        }
        return contentStore.contentURL
            .appendingPathComponent(folder)
            .appendingPathComponent(quest.slug)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if let error = loadError {
                    Text("Could not load quest content: \(error)")
                        .foregroundStyle(themeManager.colors.secondaryText)
                        .padding()
                } else {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }

                    completeButton
                }
            }
            .padding()
        }
        .background(themeManager.colors.background)
        .overlay {
            if selectedImage != nil {
                ImageViewerOverlay(image: $selectedImage)
                    .ignoresSafeArea()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(quest.title)
                    .font(themeManager.headingFont(size: 18))
                    .foregroundStyle(themeManager.colors.accent)
                    .lineLimit(1)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    progressStore.toggleQuest(quest.slug)
                } label: {
                    Image(systemName: progressStore.isQuestComplete(quest.slug) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.checkpointDone : themeManager.colors.accent)
                }
            }
        }
        .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { loadBlocks() }
    }

    @ViewBuilder
    private var completeButton: some View {
        let isComplete = progressStore.isQuestComplete(quest.slug)
        let actionLabel = quest.type == .shrine ? "Mark Shrine Complete" : "Mark Quest Complete"
        Button {
            progressStore.toggleQuest(quest.slug)
        } label: {
            HStack(spacing: 8) {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isComplete ? "Completed" : actionLabel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isComplete ? themeManager.colors.cardBackground : themeManager.colors.accent)
            .foregroundStyle(isComplete ? themeManager.colors.secondaryText : themeManager.colors.accentText)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(themeManager.colors.cardBorder, lineWidth: isComplete ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block {
        case .text(let markdown):
            if let attributed = try? AttributedString(markdown: markdown) {
                Text(attributed)
                    .font(.body)
                    .foregroundStyle(themeManager.colors.primaryText)
            } else {
                Text(markdown)
                    .font(.body)
                    .foregroundStyle(themeManager.colors.primaryText)
            }

        case .image(let filename):
            let imagePath = questContentURL.appendingPathComponent(filename).path
            if let uiImage = UIImage(contentsOfFile: imagePath) {
                Button {
                    selectedImage = uiImage
                } label: {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(themeManager.colors.cardBorder, lineWidth: 1)
                        )
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                                .padding(6)
                                .background(.black.opacity(0.5))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .padding(6)
                        }
                }
                .buttonStyle(.plain)
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
