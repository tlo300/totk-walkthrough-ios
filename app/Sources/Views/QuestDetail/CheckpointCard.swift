// CheckpointCard.swift — Inline card marking a checkpoint in quest walkthrough content.
import SwiftUI

struct CheckpointCard: View {
    let id: String
    let label: String
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(themeManager.colors.checkpointPending, lineWidth: 2)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(themeManager.colors.checkpointPending)
                    .frame(width: 9, height: 9)
            }

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(themeManager.colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
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
