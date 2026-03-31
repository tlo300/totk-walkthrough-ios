// MapScrollView.swift — Zoomable map with shrine and tower pins as UIScrollView subviews.
import SwiftUI
import UIKit

struct MapScrollView: UIViewRepresentable {
    let pins: [MapPin]
    let completedSlugs: Set<String>
    let contentURL: URL
    let onShrineTap: (String) -> Void
    let onTowerTap: (MapPin) -> Void

    /// Converts in-game world coordinates to pixel position on the map image.
    /// Y is inverted: in-game Y increases northward, image Y increases downward.
    static func worldToPixel(worldX: Double, worldY: Double, imageSize: CGSize) -> CGPoint {
        let px = (worldX - ModelConfig.mapWorldMinX)
            / (ModelConfig.mapWorldMaxX - ModelConfig.mapWorldMinX)
            * imageSize.width
        let py = (1.0 - (worldY - ModelConfig.mapWorldMinY)
            / (ModelConfig.mapWorldMaxY - ModelConfig.mapWorldMinY))
            * imageSize.height
        return CGPoint(x: px, y: py)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> UIScrollView { UIScrollView() }
    func updateUIView(_ uiView: UIScrollView, context: Context) {}

    final class Coordinator: NSObject {}
}
