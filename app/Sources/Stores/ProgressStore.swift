// ProgressStore.swift — Persists quest/tower completion state and the current bookmark.
import Foundation

@MainActor
final class ProgressStore: ObservableObject {

    struct Bookmark: Codable, Equatable {
        let questSlug: String
        let checkpointIndex: Int
    }

    @Published private(set) var completedQuests: Set<String> = []
    @Published private(set) var completedTowers: Set<String> = []
    @Published private(set) var bookmark: Bookmark?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func isQuestComplete(_ slug: String) -> Bool {
        completedQuests.contains(slug)
    }

    func toggleQuest(_ slug: String) {
        if completedQuests.contains(slug) {
            completedQuests.remove(slug)
        } else {
            completedQuests.insert(slug)
        }
        defaults.set(Array(completedQuests), forKey: ModelConfig.progressQuestsKey)
    }

    func isTowerComplete(_ slug: String) -> Bool {
        completedTowers.contains(slug)
    }

    func toggleTower(_ slug: String) {
        if completedTowers.contains(slug) {
            completedTowers.remove(slug)
        } else {
            completedTowers.insert(slug)
        }
        defaults.set(Array(completedTowers), forKey: ModelConfig.progressTowersKey)
    }

    func setBookmark(_ bookmark: Bookmark) {
        self.bookmark = bookmark
        if let data = try? JSONEncoder().encode(bookmark) {
            defaults.set(data, forKey: ModelConfig.progressBookmarkKey)
        }
    }

    func reset() {
        completedQuests = []
        completedTowers = []
        bookmark = nil
        defaults.removeObject(forKey: ModelConfig.progressQuestsKey)
        defaults.removeObject(forKey: ModelConfig.progressTowersKey)
        defaults.removeObject(forKey: ModelConfig.progressBookmarkKey)
    }

    // MARK: - Private

    private func load() {
        if let saved = defaults.object(forKey: ModelConfig.progressQuestsKey) as? [String] {
            completedQuests = Set(saved)
        }
        if let saved = defaults.object(forKey: ModelConfig.progressTowersKey) as? [String] {
            completedTowers = Set(saved)
        }
        if let data = defaults.data(forKey: ModelConfig.progressBookmarkKey),
           let saved = try? JSONDecoder().decode(Bookmark.self, from: data) {
            bookmark = saved
        }
    }
}
