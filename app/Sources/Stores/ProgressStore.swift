// ProgressStore.swift — Persists checkpoint completion state and the current bookmark.
import Foundation

@MainActor
final class ProgressStore: ObservableObject {

    struct Bookmark: Codable, Equatable {
        let questSlug: String
        let checkpointIndex: Int
    }

    @Published private(set) var completedCheckpoints: Set<String> = []
    @Published private(set) var bookmark: Bookmark?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func isCheckpointComplete(_ id: String) -> Bool {
        completedCheckpoints.contains(id)
    }

    func markCheckpoint(_ id: String) {
        completedCheckpoints.insert(id)
        persist()
    }

    func setBookmark(_ bookmark: Bookmark) {
        self.bookmark = bookmark
        if let data = try? JSONEncoder().encode(bookmark) {
            defaults.set(data, forKey: ModelConfig.progressBookmarkKey)
        }
    }

    func reset() {
        completedCheckpoints = []
        bookmark = nil
        defaults.removeObject(forKey: ModelConfig.progressStoreKey)
        defaults.removeObject(forKey: ModelConfig.progressBookmarkKey)
    }

    // MARK: - Private

    private func load() {
        if let saved = defaults.object(forKey: ModelConfig.progressStoreKey) as? [String] {
            completedCheckpoints = Set(saved)
        }
        if let data = defaults.data(forKey: ModelConfig.progressBookmarkKey),
           let saved = try? JSONDecoder().decode(Bookmark.self, from: data) {
            bookmark = saved
        }
    }

    private func persist() {
        defaults.set(Array(completedCheckpoints), forKey: ModelConfig.progressStoreKey)
    }
}
