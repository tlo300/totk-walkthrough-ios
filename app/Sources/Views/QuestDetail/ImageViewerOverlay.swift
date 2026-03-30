// ImageViewerOverlay.swift — Fullscreen dark overlay for viewing quest screenshots with zoom and gesture dismiss.
import SwiftUI

struct ImageViewerOverlay: View {
    @Binding var image: UIImage?

    @State private var dragOffset: CGFloat = 0
    @State private var zoomScale: CGFloat = 1.0

    private let dismissThreshold: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            if let img = image {
                ZoomableScrollView(image: img, zoomScale: $zoomScale)
                    .ignoresSafeArea()
                    .offset(y: max(dragOffset, 0))
                    .simultaneousGesture(swipeDownGesture)
                    .onTapGesture {
                        guard zoomScale <= 1.0 else { return }
                        dismiss()
                    }
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                    .padding()
            }
        }
        .opacity(image != nil ? backgroundOpacity : 0)
        .animation(.easeInOut(duration: 0.25), value: image != nil)
    }

    private var backgroundOpacity: Double {
        max(0, 1.0 - Double(dragOffset) / 300.0)
    }

    private var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard zoomScale <= 1.0, value.translation.height > 0 else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                guard zoomScale <= 1.0 else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                    return
                }
                if value.translation.height > dismissThreshold ||
                   value.predictedEndTranslation.height > dismissThreshold {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                }
            }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.2)) {
            image = nil
            dragOffset = 0
            zoomScale = 1.0
        }
    }
}
