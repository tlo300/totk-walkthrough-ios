// ContentStoreTests.swift — Unit tests for ContentStore.
import XCTest
@testable import TOTKWalkthrough

@MainActor
final class ContentStoreTests: XCTestCase {

    private var fixturesURL: URL {
        Bundle(for: type(of: self)).bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
    }

    func test_load_populatesQuests() async throws {
        let store = ContentStore(contentURL: fixturesURL)
        try await store.load()
        XCTAssertEqual(store.quests.count, 1)
        XCTAssertEqual(store.quests[0].slug, "test-quest")
    }

    func test_load_populatesSideQuests() async throws {
        let store = ContentStore(contentURL: fixturesURL)
        try await store.load()
        XCTAssertEqual(store.sideQuests.count, 1)
        XCTAssertEqual(store.sideQuests[0].slug, "test-side")
    }

    func test_contentBlocks_returnsBlocksForKnownQuest() async throws {
        let store = ContentStore(contentURL: fixturesURL)
        try await store.load()
        let quest = store.quests[0]
        let blocks = try store.contentBlocks(for: quest)
        XCTAssertFalse(blocks.isEmpty)
    }

    func test_contentBlocks_throwsForMissingContent() async throws {
        let store = ContentStore(contentURL: fixturesURL)
        try await store.load()
        let missing = Quest(slug: "does-not-exist", title: "Missing", type: .main)
        XCTAssertThrowsError(try store.contentBlocks(for: missing))
    }
}
