// MapStore.swift — Loads map-locations.json and provides pins filtered by map layer.
import Foundation

@MainActor
final class MapStore: ObservableObject {
    @Published private(set) var allPins: [MapPin] = []

    private let contentURL: URL

    init(contentURL: URL = Bundle.main.url(forResource: ModelConfig.contentBundlePath,
                                            withExtension: nil)
            ?? Bundle.main.bundleURL.appendingPathComponent(ModelConfig.contentBundlePath)) {
        self.contentURL = contentURL
    }

    func load() async throws {
        let url = contentURL.appendingPathComponent(ModelConfig.mapLocationsPath)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let data = try Data(contentsOf: url)
        allPins = try JSONDecoder().decode([MapPin].self, from: data)
    }

    func pins(for layer: MapLayer) -> [MapPin] {
        allPins.filter { $0.layer == layer }
    }
}
