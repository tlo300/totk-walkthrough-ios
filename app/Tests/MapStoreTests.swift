// MapStoreTests.swift — Unit tests for MapStore and worldToPixel coordinate transform.
import XCTest
@testable import TOTKWalkthrough

@MainActor
final class MapStoreTests: XCTestCase {

    private var fixturesURL: URL {
        Bundle(for: type(of: self)).bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
    }

    func test_load_populatesAllPins() async throws {
        let store = MapStore(contentURL: fixturesURL)
        try await store.load()
        XCTAssertEqual(store.allPins.count, 3)
    }

    func test_pins_filtersToSurface() async throws {
        let store = MapStore(contentURL: fixturesURL)
        try await store.load()
        let pins = store.pins(for: .surface)
        XCTAssertEqual(pins.count, 2)
        XCTAssertTrue(pins.allSatisfy { $0.layer == .surface })
    }

    func test_pins_filtersToSky() async throws {
        let store = MapStore(contentURL: fixturesURL)
        try await store.load()
        let pins = store.pins(for: .sky)
        XCTAssertEqual(pins.count, 1)
        XCTAssertEqual(pins[0].slug, "test-shrine-sky")
    }

    func test_pins_filtersToDepths_empty() async throws {
        let store = MapStore(contentURL: fixturesURL)
        try await store.load()
        XCTAssertTrue(store.pins(for: .depths).isEmpty)
    }

    func test_worldToPixel_centreMapsToCentreOfImage() {
        let size = CGSize(width: 1000, height: 1000)
        // X=0: (0 - (-5000)) / 10000 * 1000 = 500
        // Y=0 inverted: (1 - (0 - (-4000)) / 8000) * 1000 = (1 - 0.5) * 1000 = 500
        let pt = MapScrollView.worldToPixel(worldX: 0, worldY: 0, imageSize: size)
        XCTAssertEqual(pt.x, 500, accuracy: 1)
        XCTAssertEqual(pt.y, 500, accuracy: 1)
    }

    func test_worldToPixel_topLeftCorner() {
        let size = CGSize(width: 1000, height: 1000)
        // worldMinX, worldMaxY → pixel (0, 0)
        let pt = MapScrollView.worldToPixel(
            worldX: ModelConfig.mapWorldMinX,
            worldY: ModelConfig.mapWorldMaxY,
            imageSize: size
        )
        XCTAssertEqual(pt.x, 0, accuracy: 1)
        XCTAssertEqual(pt.y, 0, accuracy: 1)
    }

    func test_worldToPixel_bottomRightCorner() {
        let size = CGSize(width: 1000, height: 1000)
        // worldMaxX, worldMinY → pixel (1000, 1000)
        let pt = MapScrollView.worldToPixel(
            worldX: ModelConfig.mapWorldMaxX,
            worldY: ModelConfig.mapWorldMinY,
            imageSize: size
        )
        XCTAssertEqual(pt.x, 1000, accuracy: 1)
        XCTAssertEqual(pt.y, 1000, accuracy: 1)
    }
}
