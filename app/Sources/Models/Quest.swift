// Quest.swift — Quest and SideQuest data model loaded from quest-order.json.
import Foundation

enum QuestType: String, Codable {
    case main
    case side
    case shrine
    case adventure
}

struct Quest: Identifiable, Codable, Hashable {
    let slug: String
    let title: String
    let type: QuestType

    var id: String { slug }
}

struct QuestOrder: Codable {
    let quests: [Quest]
}
