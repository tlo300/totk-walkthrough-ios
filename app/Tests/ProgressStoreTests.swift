// ProgressStoreTests.swift — Unit tests for ProgressStore.
import XCTest
@testable import TOTKWalkthrough

@MainActor
final class ProgressStoreTests: XCTestCase {

    private func makeStore() -> ProgressStore {
        let suite = UUID().uuidString
        return ProgressStore(defaults: UserDefaults(suiteName: suite)!)
    }

    func test_initialState_noCompletedQuests() {
        let store = makeStore()
        XCTAssertTrue(store.completedQuests.isEmpty)
    }

    func test_toggleQuest_marksComplete() {
        let store = makeStore()
        store.toggleQuest("find-zelda")
        XCTAssertTrue(store.isQuestComplete("find-zelda"))
    }

    func test_toggleQuest_togglesOff() {
        let store = makeStore()
        store.toggleQuest("find-zelda")
        store.toggleQuest("find-zelda")
        XCTAssertFalse(store.isQuestComplete("find-zelda"))
    }

    func test_toggleQuest_doesNotAffectOtherQuests() {
        let store = makeStore()
        store.toggleQuest("find-zelda")
        XCTAssertFalse(store.isQuestComplete("other-quest"))
    }

    func test_setBookmark_persists() {
        let store = makeStore()
        let bookmark = ProgressStore.Bookmark(questSlug: "find-zelda", checkpointIndex: 2)
        store.setBookmark(bookmark)
        XCTAssertEqual(store.bookmark?.questSlug, "find-zelda")
        XCTAssertEqual(store.bookmark?.checkpointIndex, 2)
    }

    func test_reset_clearsQuestsAndBookmark() {
        let store = makeStore()
        store.toggleQuest("find-zelda")
        store.setBookmark(ProgressStore.Bookmark(questSlug: "find-zelda", checkpointIndex: 0))
        store.reset()
        XCTAssertTrue(store.completedQuests.isEmpty)
        XCTAssertNil(store.bookmark)
    }

    func test_persistence_acrossInstances() {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        let store1 = ProgressStore(defaults: defaults)
        store1.toggleQuest("persistent-quest")

        let store2 = ProgressStore(defaults: defaults)
        XCTAssertTrue(store2.isQuestComplete("persistent-quest"))
    }

    func test_initialState_noCompletedTowers() {
        let store = makeStore()
        XCTAssertTrue(store.completedTowers.isEmpty)
    }

    func test_toggleTower_marksComplete() {
        let store = makeStore()
        store.toggleTower("akkala-skyview-tower")
        XCTAssertTrue(store.isTowerComplete("akkala-skyview-tower"))
    }

    func test_toggleTower_togglesOff() {
        let store = makeStore()
        store.toggleTower("akkala-skyview-tower")
        store.toggleTower("akkala-skyview-tower")
        XCTAssertFalse(store.isTowerComplete("akkala-skyview-tower"))
    }

    func test_toggleTower_doesNotAffectOtherTowers() {
        let store = makeStore()
        store.toggleTower("akkala-skyview-tower")
        XCTAssertFalse(store.isTowerComplete("eldin-skyview-tower"))
    }

    func test_reset_clearsCompletedTowers() {
        let store = makeStore()
        store.toggleTower("akkala-skyview-tower")
        store.reset()
        XCTAssertTrue(store.completedTowers.isEmpty)
    }

    func test_tower_persistence_acrossInstances() {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        let store1 = ProgressStore(defaults: defaults)
        store1.toggleTower("akkala-skyview-tower")

        let store2 = ProgressStore(defaults: defaults)
        XCTAssertTrue(store2.isTowerComplete("akkala-skyview-tower"))
    }
}
