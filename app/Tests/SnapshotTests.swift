// SnapshotTests.swift — SwiftUI snapshot tests for major screens.
import XCTest
import SnapshotTesting
import SwiftUI
@testable import TOTKWalkthrough

final class SnapshotTests: XCTestCase {

    // Shared fixture stores
    private var contentStore: ContentStore!
    private var progressStore: ProgressStore!
    private var themeManager: ThemeManager!

    override func setUpWithError() throws {
        let fixturesURL = Bundle(for: type(of: self)).bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        contentStore = ContentStore(contentURL: fixturesURL)
        progressStore = ProgressStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        themeManager = ThemeManager()
    }

    private func snapshotView<V: View>(_ view: V, named name: String, record: Bool = false) {
        let vc = UIHostingController(rootView:
            view
                .environmentObject(contentStore)
                .environmentObject(progressStore)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
        )
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844) // iPhone 14 size
        assertSnapshot(of: vc, as: .image(on: .iPhone13Pro), named: name, record: record)
    }

    func test_walkthroughTab_snapshot() async throws {
        try await contentStore.load()
        snapshotView(WalkthroughTabView(), named: "WalkthroughTab")
    }

    func test_questsTab_snapshot() async throws {
        try await contentStore.load()
        snapshotView(QuestsTabView(), named: "QuestsTab")
    }

    func test_sideQuestsTab_snapshot() async throws {
        try await contentStore.load()
        snapshotView(SideQuestsTabView(), named: "SideQuestsTab")
    }

    func test_progressTab_snapshot() async throws {
        try await contentStore.load()
        snapshotView(ProgressTabView(), named: "ProgressTab")
    }

    func test_questDetail_snapshot() async throws {
        try await contentStore.load()
        guard let quest = contentStore.quests.first else {
            XCTFail("No quests loaded from fixtures")
            return
        }
        snapshotView(QuestDetailView(quest: quest), named: "QuestDetail")
    }
}
