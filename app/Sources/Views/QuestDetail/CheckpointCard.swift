// CheckpointCard.swift — Inline card for a quest checkpoint with a "Mark Done" button.
import SwiftUI

struct CheckpointCard: View {
    let id: String
    let label: String
    @EnvironmentObject private var progressStore: ProgressStore

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(progressStore.isCheckpointComplete(id) ? Color.green : Color.yellow, lineWidth: 2)
                    .frame(width: 22, height: 22)
                if progressStore.isCheckpointComplete(id) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 9, height: 9)
                }
            }

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !progressStore.isCheckpointComplete(id) {
                Button("Mark Done") {
                    progressStore.markCheckpoint(id)
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.yellow)
                .foregroundColor(.black)
                .clipShape(Capsule())
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
