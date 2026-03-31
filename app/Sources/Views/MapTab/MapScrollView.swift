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
    /// Y is inverted: in-game Y increases northward, image pixel Y increases downward.
    static func worldToPixel(worldX: Double, worldY: Double, imageSize: CGSize) -> CGPoint {
        let px = (worldX - ModelConfig.mapWorldMinX)
            / (ModelConfig.mapWorldMaxX - ModelConfig.mapWorldMinX)
            * imageSize.width
        let py = (1.0 - (worldY - ModelConfig.mapWorldMinY)
            / (ModelConfig.mapWorldMaxY - ModelConfig.mapWorldMinY))
            * imageSize.height
        return CGPoint(x: px, y: py)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onShrineTap: onShrineTap, onTowerTap: onTowerTap)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 0.3
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .systemBackground

        // Container holds image + pins together so they zoom/pan as a unit
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            container.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            container.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            container.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            container.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])

        let imagePath = contentURL.appendingPathComponent(ModelConfig.mapImagePath).path
        let image = UIImage(contentsOfFile: imagePath) ?? UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.frame = container.bounds
        container.addSubview(imageView)

        context.coordinator.container = container
        context.coordinator.pins = pins
        context.coordinator.completedSlugs = completedSlugs
        context.coordinator.onShrineTap = onShrineTap
        context.coordinator.onTowerTap = onTowerTap

        // Add pins after the initial layout pass (bounds are zero until then)
        DispatchQueue.main.async {
            context.coordinator.refreshPins()
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.pins = pins
        context.coordinator.completedSlugs = completedSlugs
        context.coordinator.onShrineTap = onShrineTap
        context.coordinator.onTowerTap = onTowerTap
        context.coordinator.refreshPins()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var container: UIView?
        var pins: [MapPin] = []
        var completedSlugs: Set<String> = []
        var onShrineTap: (String) -> Void
        var onTowerTap: (MapPin) -> Void

        init(onShrineTap: @escaping (String) -> Void, onTowerTap: @escaping (MapPin) -> Void) {
            self.onShrineTap = onShrineTap
            self.onTowerTap = onTowerTap
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            container
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let vInset = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
            let hInset = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
            scrollView.contentInset = UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset)
        }

        func refreshPins() {
            guard let container else { return }
            // Remove existing pin buttons before re-adding
            container.subviews.filter { $0 is UIButton }.forEach { $0.removeFromSuperview() }

            let imageSize = container.bounds.size
            guard imageSize.width > 0 else { return }

            for pin in pins {
                let center = MapScrollView.worldToPixel(worldX: pin.x, worldY: pin.y, imageSize: imageSize)
                let size: CGFloat = pin.type == .shrine ? 16 : 14
                let button = UIButton(type: .custom)
                button.frame = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)

                if pin.type == .shrine {
                    button.backgroundColor = UIColor(red: 0.31, green: 0.76, blue: 0.97, alpha: 1)
                    button.layer.cornerRadius = size / 2
                } else {
                    // Tower: orange rotated square
                    button.backgroundColor = UIColor(red: 1.0, green: 0.72, blue: 0.30, alpha: 1)
                    button.transform = CGAffineTransform(rotationAngle: .pi / 4)
                }
                button.layer.borderWidth = 1.5
                button.layer.borderColor = UIColor.white.cgColor
                button.alpha = completedSlugs.contains(pin.slug) ? 0.4 : 1.0

                let capturedPin = pin
                button.addAction(UIAction { [weak self] _ in
                    if capturedPin.type == .shrine {
                        self?.onShrineTap(capturedPin.slug)
                    } else {
                        self?.onTowerTap(capturedPin)
                    }
                }, for: .touchUpInside)
                container.addSubview(button)
            }
        }
    }
}
