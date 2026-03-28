// ProgressTabView.swift — Completion stats and progress reset.
import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @State private var showingResetConfirm = false

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
                Section("Main Quests") {
                    LabeledContent("Total Quests", value: "\(contentStore.quests.count)")
                }
                Section("Side Quests") {
                    LabeledContent("Total Side Quests", value: "\(contentStore.sideQuests.count)")
                }
                Section("Checkpoints") {
                    LabeledContent("Completed", value: "\(completedCount) / \(totalCheckpoints)")
                    if totalCheckpoints > 0 {
                        ProgressView(value: Double(completedCount), total: Double(totalCheckpoints))
                            .tint(.green)
                    }
                }
                Section {
                    Button("Reset All Progress", role: .destructive) {
                        showingResetConfirm = true
                    }
                }
            }
            .navigationTitle("Progress")
            .confirmationDialog("Reset all progress?",
                                isPresented: $showingResetConfirm,
                                titleVisibility: .visible) {
                Button("Reset", role: .destructive) { progressStore.reset() }
            } message: {
                Text("This will clear all completed checkpoints and your bookmark.")
            }
        }
    }
}
