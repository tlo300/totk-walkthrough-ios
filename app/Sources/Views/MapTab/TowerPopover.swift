// TowerPopover.swift — Sheet shown when a Skyview Tower pin is tapped.
import SwiftUI

struct TowerPopover: View {
    let pin: MapPin
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(pin.name ?? pin.slug)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(themeManager.colors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                Button {
                    progressStore.toggleTower(pin.slug)
                } label: {
                    Label(
                        progressStore.isTowerComplete(pin.slug) ? "Mark Incomplete" : "Mark Complete",
                        systemImage: progressStore.isTowerComplete(pin.slug)
                            ? "xmark.circle" : "checkmark.circle"
                    )
                    .font(.headline)
                    .foregroundStyle(
                        progressStore.isTowerComplete(pin.slug)
                            ? themeManager.colors.secondaryText
                            : themeManager.colors.accent
                    )
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding(.horizontal)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(themeManager.colors.accent)
                }
            }
        }
    }
}
