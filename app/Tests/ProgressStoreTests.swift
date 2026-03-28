// ProgressStoreTests.swift — Unit tests for ProgressStore.
import XCTest
@testable import TOTKWalkthrough

@MainActor
final class ProgressStoreTests: XCTestCase {

    private func makeStore() -> ProgressStore {
        // Isolated UserDefaults so tests don't affect each other
        let suite = UUID().uuidString
        return ProgressStore(defaults: UserDefaults(suiteName: suite)!)
    }

    func test_initialState_noCompletedCheckpoints() {
        let store = makeStore()
        XCTAssertTrue(store.completedCheckpoints.isEmpty)
    }

    func test_markCheckpoint_addsToCompleted() {
        let store = makeStore()
        store.markCheckpoint("gate-reached")
        XCTAssertTrue(store.completedCheckpoints.contains("gate-reached"))
    }

    func test_markCheckpoint_isIdempotent() {
        let store = makeStore()
        store.markCheckpoint("gate-reached")
        store.markCheckpoint("gate-reached")
        XCTAssertEqual(store.completedCheckpoints.count, 1)
    }

    func test_isCheckpointComplete_returnsTrueAfterMark() {
        let store = makeStore()
        store.markCheckpoint("cp-1")
        XCTAssertTrue(store.isCheckpointComplete("cp-1"))
    }

    func test_setBookmark_persists() {
        let store = makeStore()
        let bookmark = ProgressStore.Bookmark(questSlug: "find-zelda", checkpointIndex: 2)
        store.setBookmark(bookmark)
        XCTAssertEqual(store.bookmark?.questSlug, "find-zelda")
        XCTAssertEqual(store.bookmark?.checkpointIndex, 2)
    }

    func test_reset_clearsCheckpointsAndBookmark() {
        let store = makeStore()
        store.markCheckpoint("cp-1")
        store.setBookmark(ProgressStore.Bookmark(questSlug: "find-zelda", checkpointIndex: 0))
        store.reset()
        XCTAssertTrue(store.completedCheckpoints.isEmpty)
        XCTAssertNil(store.bookmark)
    }

    func test_persistence_acrossInstances() {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        let store1 = ProgressStore(defaults: defaults)
        store1.markCheckpoint("persistent-cp")

        let store2 = ProgressStore(defaults: defaults)
        XCTAssertTrue(store2.completedCheckpoints.contains("persistent-cp"))
    }
}
