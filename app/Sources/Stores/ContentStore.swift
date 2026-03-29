// ContentStore.swift — Loads quest-order.json, shrines/index.json, side-quests/index.json,
// adventures/index.json, and quest content from the app bundle.
import Foundation

@MainActor
final class ContentStore: ObservableObject {

    enum ContentError: Error {
        case contentFileNotFound(String)
        case questOrderNotFound
    }

    @Published private(set) var quests: [Quest] = []
    @Published private(set) var sideQuests: [Quest] = []
    @Published private(set) var shrines: [Quest] = []
    @Published private(set) var adventures: [Quest] = []

    let contentURL: URL

    init(contentURL: URL = Bundle.main.url(forResource: ModelConfig.contentBundlePath,
                                            withExtension: nil)
            ?? Bundle.main.bundleURL.appendingPathComponent(ModelConfig.contentBundlePath)) {
        self.contentURL = contentURL
    }

    func load() async throws {
        // Main walkthrough quests
        let orderURL = contentURL.appendingPathComponent(ModelConfig.questOrderFilename)
        guard FileManager.default.fileExists(atPath: orderURL.path) else {
            throw ContentError.questOrderNotFound
        }
        let orderData = try Data(contentsOf: orderURL)
        let order = try JSONDecoder().decode(QuestOrder.self, from: orderData)
        quests = order.quests

        // Shrines
        let shrinesURL = contentURL.appendingPathComponent(ModelConfig.shrinesIndexPath)
        if FileManager.default.fileExists(atPath: shrinesURL.path) {
            let shrinesData = try Data(contentsOf: shrinesURL)
            let shrineOrder = try JSONDecoder().decode(QuestOrder.self, from: shrinesData)
            shrines = shrineOrder.quests
        }

        // Side quests (scraped index)
        let sideQuestsURL = contentURL.appendingPathComponent(ModelConfig.sideQuestsIndexPath)
        if FileManager.default.fileExists(atPath: sideQuestsURL.path) {
            let sideQuestsData = try Data(contentsOf: sideQuestsURL)
            let sideQuestOrder = try JSONDecoder().decode(QuestOrder.self, from: sideQuestsData)
            sideQuests = sideQuestOrder.quests
        }

        // Adventures (scraped index)
        let adventuresURL = contentURL.appendingPathComponent(ModelConfig.adventuresIndexPath)
        if FileManager.default.fileExists(atPath: adventuresURL.path) {
            let adventuresData = try Data(contentsOf: adventuresURL)
            let adventureOrder = try JSONDecoder().decode(QuestOrder.self, from: adventuresData)
            adventures = adventureOrder.quests
        }
    }

    func contentBlocks(for quest: Quest) throws -> [ContentBlock] {
        let folder: String
        switch quest.type {
        case .main: folder = "quests"
        case .side: folder = "side-quests"
        case .shrine: folder = "shrines"
        case .adventure: folder = "adventures"
        }
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
