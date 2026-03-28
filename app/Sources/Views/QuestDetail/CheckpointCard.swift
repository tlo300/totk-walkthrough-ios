// CheckpointCard.swift — Inline card for a quest checkpoint with a "Mark Done" button.
import SwiftUI

struct CheckpointCard: View {
    let id: String
    let label: String
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(
                        progressStore.isCheckpointComplete(id)
                            ? themeManager.colors.checkpointDone
                            : themeManager.colors.checkpointPending,
                        lineWidth: 2
                    )
                    .frame(width: 22, height: 22)
                if progressStore.isCheckpointComplete(id) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(themeManager.colors.checkpointDone)
                } else {
                    Circle()
                        .fill(themeManager.colors.checkpointPending)
                        .frame(width: 9, height: 9)
                }
            }

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(themeManager.colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !progressStore.isCheckpointComplete(id) {
                Button("Mark Done") {
                    progressStore.markCheckpoint(id)
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(themeManager.colors.accent)
                .foregroundStyle(themeManager.colors.accentText)
                .clipShape(Capsule())
            }
        }
        .padding(10)
        .background(themeManager.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(themeManager.colors.cardBorder, lineWidth: 1)
        )
        .shadow(
            color: themeManager.colors.glow ?? .clear,
            radius: 4, x: 0, y: 0
        )
    }
}
