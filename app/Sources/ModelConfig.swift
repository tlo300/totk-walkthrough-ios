// ModelConfig.swift — Central configuration constants. All tuneable values live here.
import Foundation

enum ModelConfig {
    static let contentBundlePath = "Content"
    static let questOrderFilename = "quest-order.json"
    static let shrinesIndexPath = "shrines/index.json"
    static let sideQuestsIndexPath = "side-quests/index.json"
    static let adventuresIndexPath = "adventures/index.json"
    static let progressBookmarkKey = "com.totk.bookmark"
    static let progressQuestsKey = "com.totk.quests"
    static let mapLocationsPath = "map-locations.json"
    static let mapImagePath = "map-base.png"
    static let progressTowersKey = "com.totk.towers"
    // World coordinate bounds derived from alshival/totk-map shrines.csv
    static let mapWorldMinX: Double = -5000
    static let mapWorldMaxX: Double =  5000
    static let mapWorldMinY: Double = -4000
    static let mapWorldMaxY: Double =  4000
    static let regionOrder = [
        "Great Sky Island", "Central Hyrule", "Eldin", "Akkala",
        "Hebra", "Lanayru", "Necluda", "Faron", "Gerudo"
    ]
}
