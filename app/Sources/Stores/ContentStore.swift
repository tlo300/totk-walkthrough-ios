// ContentStore.swift — Loads quest-order.json and quest content from the app bundle.
import Foundation

@MainActor
final class ContentStore: ObservableObject {

    enum ContentError: Error {
        case contentFileNotFound(String)
        case questOrderNotFound
    }

    @Published private(set) var quests: [Quest] = []
    @Published private(set) var sideQuests: [Quest] = []

    private let contentURL: URL

    init(contentURL: URL = Bundle.main.url(forResource: ModelConfig.contentBundlePath,
                                            withExtension: nil)
            ?? Bundle.main.bundleURL.appendingPathComponent(ModelConfig.contentBundlePath)) {
        self.contentURL = contentURL
    }

    func load() async throws {
        let orderURL = contentURL.appendingPathComponent(ModelConfig.questOrderFilename)
        guard FileManager.default.fileExists(atPath: orderURL.path) else {
            throw ContentError.questOrderNotFound
        }
        let data = try Data(contentsOf: orderURL)
        let order = try JSONDecoder().decode(QuestOrder.self, from: data)
        quests = order.quests
        sideQuests = order.sideQuests
    }

    func contentBlocks(for quest: Quest) throws -> [ContentBlock] {
        let folder = quest.type == .main ? "quests" : "side-quests"
        let mdURL = contentURL
            .appendingPathComponent(folder)
            .appendingPathComponent(quest.slug)
            .appendingPathComponent("content.md")
        guard FileManager.default.fileExists(atPath: mdURL.path) else {
            throw ContentError.contentFileNotFound(mdURL.path)
        }
        let markdown = try String(contentsOf: mdURL, encoding: .utf8)
        return try QuestContentParser().parse(markdown)
    }
}
