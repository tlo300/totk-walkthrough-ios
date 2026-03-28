# Quest Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users tick off quests and side quests as complete via a tappable circle on the overview list, a swipe action on list rows, and a complete button at the bottom of the quest detail page.

**Architecture:** Replace the per-checkpoint completion model with a quest-level `completedQuests: Set<String>` stored in `ProgressStore`. All three UI interaction points call the same `toggleQuest(_ slug: String)` method. `ProgressTabView` shows per-list completion stats instead of checkpoint counts.

**Tech Stack:** Swift 5.9+, SwiftUI, UserDefaults persistence, XCTest

---

## File Map

| File | Action | What changes |
|------|--------|-------------|
| `app/Sources/ModelConfig.swift` | Modify | Add `progressQuestsKey` |
| `app/Sources/Stores/ProgressStore.swift` | Modify | Replace checkpoint API with quest API |
| `app/Tests/ProgressStoreTests.swift` | Modify | Replace checkpoint tests with quest tests |
| `app/Sources/Views/QuestDetail/CheckpointCard.swift` | Modify | Remove `progressStore` dependency and Mark Done button |
| `app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift` | Modify | Tappable circle + swipe action; use `progressStore.isQuestComplete` |
| `app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift` | Modify | Add `progressStore`, circle button, swipe action |
| `app/Sources/Views/QuestDetail/QuestDetailView.swift` | Modify | Add complete button after content blocks |
| `app/Sources/Views/ProgressTab/ProgressTabView.swift` | Modify | Show quest completion stats instead of checkpoint counts |

---

## Task 1: Update ProgressStore and ModelConfig

**Files:**
- Modify: `app/Sources/ModelConfig.swift`
- Modify: `app/Sources/Stores/ProgressStore.swift`
- Modify: `app/Tests/ProgressStoreTests.swift`

- [ ] **Step 1: Replace ProgressStoreTests with quest-level tests**

Replace the entire content of `app/Tests/ProgressStoreTests.swift`:

```swift
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
}
```

- [ ] **Step 2: Run tests — expect compile failure on missing ProgressStore API**

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|FAILED|PASSED)"
```

Expected: compile errors referencing `completedQuests`, `isQuestComplete`, `toggleQuest` not found.

- [ ] **Step 3: Add progressQuestsKey to ModelConfig**

Replace the content of `app/Sources/ModelConfig.swift`:

```swift
// ModelConfig.swift — Central configuration constants. All tuneable values live here.
import Foundation

enum ModelConfig {
    static let contentBundlePath = "Content"
    static let questOrderFilename = "quest-order.json"
    static let progressStoreKey = "com.totk.progress"
    static let progressBookmarkKey = "com.totk.bookmark"
    static let progressQuestsKey = "com.totk.quests"
}
```

- [ ] **Step 4: Replace ProgressStore with quest-level API**

Replace the entire content of `app/Sources/Stores/ProgressStore.swift`:

```swift
// ProgressStore.swift — Persists quest completion state and the current bookmark.
import Foundation

@MainActor
final class ProgressStore: ObservableObject {

    struct Bookmark: Codable, Equatable {
        let questSlug: String
        let checkpointIndex: Int
    }

    @Published private(set) var completedQuests: Set<String> = []
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
        persistQuests()
    }

    func setBookmark(_ bookmark: Bookmark) {
        self.bookmark = bookmark
        if let data = try? JSONEncoder().encode(bookmark) {
            defaults.set(data, forKey: ModelConfig.progressBookmarkKey)
        }
    }

    func reset() {
        completedQuests = []
        bookmark = nil
        defaults.removeObject(forKey: ModelConfig.progressQuestsKey)
        defaults.removeObject(forKey: ModelConfig.progressBookmarkKey)
    }

    // MARK: - Private

    private func load() {
        if let saved = defaults.object(forKey: ModelConfig.progressQuestsKey) as? [String] {
            completedQuests = Set(saved)
        }
        if let data = defaults.data(forKey: ModelConfig.progressBookmarkKey),
           let saved = try? JSONDecoder().decode(Bookmark.self, from: data) {
            bookmark = saved
        }
    }

    private func persistQuests() {
        defaults.set(Array(completedQuests), forKey: ModelConfig.progressQuestsKey)
    }
}
```

- [ ] **Step 5: Run ProgressStoreTests — expect all pass**

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TOTKWalkthroughTests/ProgressStoreTests 2>&1 | grep -E "(error:|FAILED|PASSED|✓|✗)"
```

Expected: all 7 tests PASSED.

- [ ] **Step 6: Commit**

```bash
git add app/Sources/ModelConfig.swift app/Sources/Stores/ProgressStore.swift app/Tests/ProgressStoreTests.swift
git commit -m "feat: replace checkpoint tracking with quest-level completion in ProgressStore"
```

---

## Task 2: Simplify CheckpointCard

**Files:**
- Modify: `app/Sources/Views/QuestDetail/CheckpointCard.swift`

The card keeps its visual appearance but removes the `progressStore` environment object dependency and the "Mark Done" button. The circle always shows as a structural marker (pending style).

- [ ] **Step 1: Replace CheckpointCard**

Replace the entire content of `app/Sources/Views/QuestDetail/CheckpointCard.swift`:

```swift
// CheckpointCard.swift — Inline card marking a checkpoint in quest walkthrough content.
import SwiftUI

struct CheckpointCard: View {
    let id: String
    let label: String
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(themeManager.colors.checkpointPending, lineWidth: 2)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(themeManager.colors.checkpointPending)
                    .frame(width: 9, height: 9)
            }

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(themeManager.colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(themeManager.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(themeManager.colors.cardBorder, lineWidth: 1)
        )
        .shadow(
            color: themeManager.colors.glow ?? .clear,
            radius: 4, x: 0, y: 0
        )
    }
}
```

- [ ] **Step 2: Build to confirm no compile errors**

```
xcodebuild build -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/QuestDetail/CheckpointCard.swift
git commit -m "feat: simplify CheckpointCard to structural marker, remove Mark Done button"
```

---

## Task 3: Update WalkthroughTabView

**Files:**
- Modify: `app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift`

Replace the `isQuestComplete(_ quest: Quest) -> Bool` helper (which derived completion from checkpoints) with `progressStore.isQuestComplete(quest.slug)` directly. Split the `NavigationLink` row into a tappable circle button + a `NavigationLink` for the title. Add swipe action.

- [ ] **Step 1: Replace WalkthroughTabView**

Replace the entire content of `app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift`:

```swift
// WalkthroughTabView.swift — Linear quest walkthrough with progress and bookmark.
import SwiftUI

struct WalkthroughTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    private var completionFraction: Double {
        let total = contentStore.quests.count
        guard total > 0 else { return 0 }
        let done = contentStore.quests.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Main Quest Progress")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(themeManager.colors.primaryText)
                            Spacer()
                            Text("\(Int(completionFraction * Double(contentStore.quests.count))) / \(contentStore.quests.count)")
                                .font(.subheadline)
                                .foregroundStyle(themeManager.colors.accent)
                        }
                        ProgressView(value: completionFraction)
                            .tint(themeManager.colors.progressFill)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(themeManager.colors.cardBackground)

                    BookmarkCard(quests: contentStore.quests)
                        .listRowBackground(themeManager.colors.cardBackground)
                }

                Section {
                    ForEach(contentStore.quests) { quest in
                        HStack(spacing: 12) {
                            Button {
                                progressStore.toggleQuest(quest.slug)
                            } label: {
                                Image(systemName: progressStore.isQuestComplete(quest.slug) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: QuestDetailView(quest: quest)) {
                                Text(quest.title)
                                    .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                    .strikethrough(progressStore.isQuestComplete(quest.slug))
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                progressStore.toggleQuest(quest.slug)
                            } label: {
                                Label(
                                    progressStore.isQuestComplete(quest.slug) ? "Undo" : "Done",
                                    systemImage: progressStore.isQuestComplete(quest.slug) ? "arrow.uturn.backward" : "checkmark"
                                )
                            }
                            .tint(progressStore.isQuestComplete(quest.slug) ? .gray : .green)
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Quest Order")
                        .foregroundStyle(themeManager.colors.sectionLabel)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Walkthrough")
                        .font(themeManager.headingFont(size: 20))
                        .foregroundStyle(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(themeManager.colors.accent)
                    }
                }
            }
            .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 2: Build to confirm no compile errors**

```
xcodebuild build -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift
git commit -m "feat: add tappable circle and swipe-to-complete to WalkthroughTabView"
```

---

## Task 4: Update SideQuestsTabView

**Files:**
- Modify: `app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift`

`SideQuestsTabView` currently has no circle indicator and no `progressStore`. Add both, plus swipe action, matching the WalkthroughTabView row structure.

- [ ] **Step 1: Replace SideQuestsTabView**

Replace the entire content of `app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift`:

```swift
// SideQuestsTabView.swift — Browsable list of all side quests with completion tracking.
import SwiftUI

struct SideQuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(contentStore.sideQuests) { quest in
                    HStack(spacing: 12) {
                        Button {
                            progressStore.toggleQuest(quest.slug)
                        } label: {
                            Image(systemName: progressStore.isQuestComplete(quest.slug) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: QuestDetailView(quest: quest)) {
                            Text(quest.title)
                                .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                .strikethrough(progressStore.isQuestComplete(quest.slug))
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            progressStore.toggleQuest(quest.slug)
                        } label: {
                            Label(
                                progressStore.isQuestComplete(quest.slug) ? "Undo" : "Done",
                                systemImage: progressStore.isQuestComplete(quest.slug) ? "arrow.uturn.backward" : "checkmark"
                            )
                        }
                        .tint(progressStore.isQuestComplete(quest.slug) ? .gray : .green)
                    }
                    .listRowBackground(themeManager.colors.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Side Quests")
                        .font(themeManager.headingFont(size: 20))
                        .foregroundStyle(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(themeManager.colors.accent)
                    }
                }
            }
            .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 2: Build to confirm no compile errors**

```
xcodebuild build -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift
git commit -m "feat: add tappable circle and swipe-to-complete to SideQuestsTabView"
```

---

## Task 5: Add Complete Button to QuestDetailView

**Files:**
- Modify: `app/Sources/Views/QuestDetail/QuestDetailView.swift`

Add a full-width complete/undo button at the bottom of the scroll content, after all walkthrough blocks.

- [ ] **Step 1: Replace QuestDetailView**

Replace the entire content of `app/Sources/Views/QuestDetail/QuestDetailView.swift`:

```swift
// QuestDetailView.swift — Scrollable quest content: text, images, and checkpoint cards.
import SwiftUI

struct QuestDetailView: View {
    let quest: Quest
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var blocks: [ContentBlock] = []
    @State private var loadError: String?

    private var questContentURL: URL {
        let folder = quest.type == .main ? "quests" : "side-quests"
        return contentStore.contentURL
            .appendingPathComponent(folder)
            .appendingPathComponent(quest.slug)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if let error = loadError {
                    Text("Could not load quest content: \(error)")
                        .foregroundStyle(themeManager.colors.secondaryText)
                        .padding()
                } else {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }

                    completeButton
                }
            }
            .padding()
        }
        .background(themeManager.colors.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(quest.title)
                    .font(themeManager.headingFont(size: 18))
                    .foregroundStyle(themeManager.colors.accent)
                    .lineLimit(1)
            }
        }
        .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { loadBlocks() }
    }

    @ViewBuilder
    private var completeButton: some View {
        let isComplete = progressStore.isQuestComplete(quest.slug)
        Button {
            progressStore.toggleQuest(quest.slug)
        } label: {
            HStack(spacing: 8) {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(isComplete ? "Completed" : "Mark Quest Complete")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isComplete ? themeManager.colors.cardBackground : themeManager.colors.accent)
            .foregroundStyle(isComplete ? themeManager.colors.secondaryText : themeManager.colors.accentText)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(themeManager.colors.cardBorder, lineWidth: isComplete ? 1 : 0)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block {
        case .text(let markdown):
            if let attributed = try? AttributedString(markdown: markdown) {
                Text(attributed)
                    .font(.body)
                    .foregroundStyle(themeManager.colors.primaryText)
            } else {
                Text(markdown)
                    .font(.body)
                    .foregroundStyle(themeManager.colors.primaryText)
            }

        case .image(let filename):
            let imagePath = questContentURL.appendingPathComponent(filename).path
            if let uiImage = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(themeManager.colors.cardBorder, lineWidth: 1)
                    )
            }

        case .checkpoint(let id, let label):
            CheckpointCard(id: id, label: label)
        }
    }

    private func loadBlocks() {
        do {
            blocks = try contentStore.contentBlocks(for: quest)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
```

- [ ] **Step 2: Build to confirm no compile errors**

```
xcodebuild build -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|BUILD SUCCEEDED|BUILD FAILED)"
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/QuestDetail/QuestDetailView.swift
git commit -m "feat: add Mark Quest Complete button to QuestDetailView"
```

---

## Task 6: Update ProgressTabView

**Files:**
- Modify: `app/Sources/Views/ProgressTab/ProgressTabView.swift`

Replace checkpoint-based stats with quest completion counts. Show a progress bar for both main quests and side quests. Remove the "Checkpoints" section.

- [ ] **Step 1: Replace ProgressTabView**

Replace the entire content of `app/Sources/Views/ProgressTab/ProgressTabView.swift`:

```swift
// ProgressTabView.swift — Completion stats and progress reset.
import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingResetConfirm = false
    @State private var showingSettings = false

    private var completedMainCount: Int {
        contentStore.quests.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    private var completedSideCount: Int {
        contentStore.sideQuests.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Completed", value: "\(completedMainCount) / \(contentStore.quests.count)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                    if contentStore.quests.count > 0 {
                        ProgressView(value: Double(completedMainCount), total: Double(contentStore.quests.count))
                            .tint(themeManager.colors.progressFill)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Main Quests").foregroundStyle(themeManager.colors.sectionLabel)
                }

                Section {
                    LabeledContent("Completed", value: "\(completedSideCount) / \(contentStore.sideQuests.count)")
                        .foregroundStyle(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                    if contentStore.sideQuests.count > 0 {
                        ProgressView(value: Double(completedSideCount), total: Double(contentStore.sideQuests.count))
                            .tint(themeManager.colors.progressFill)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Side Quests").foregroundStyle(themeManager.colors.sectionLabel)
                }

                Section {
                    Button("Reset All Progress", role: .destructive) {
                        showingResetConfirm = true
                    }
                    .listRowBackground(themeManager.colors.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Progress")
                        .font(themeManager.headingFont(size: 20))
                        .foregroundStyle(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(themeManager.colors.accent)
                    }
                }
            }
            .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .confirmationDialog("Reset all progress?",
                                isPresented: $showingResetConfirm,
                                titleVisibility: .visible) {
                Button("Reset", role: .destructive) { progressStore.reset() }
            } message: {
                Text("This will clear all completed quests and your bookmark.")
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 2: Run all tests**

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(error:|FAILED|PASSED|TEST SUITE)"
```

Expected: all tests PASSED, no errors.

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/ProgressTab/ProgressTabView.swift
git commit -m "feat: show quest completion stats in ProgressTabView"
```
