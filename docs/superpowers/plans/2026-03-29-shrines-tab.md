# Shrines Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Shrines tab to the app backed by the 5 already-scraped shrine records, with per-shrine detail pages and completion tracking.

**Architecture:** Extend `QuestType` with `.shrine`, teach `ContentStore` to load from `shrines/index.json`, create `ShrinesTabView` mirroring `WalkthroughTabView`, and reuse `QuestDetailView` for shrine detail pages.

**Tech Stack:** Swift 5.9, SwiftUI, XCTest, SnapshotTesting, Python scraper (BeautifulSoup / yaml)

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `app/Sources/Models/Quest.swift` | Modify | Add `.shrine` to `QuestType` |
| `app/Sources/ModelConfig.swift` | Modify | Add `shrinesIndexPath` constant |
| `app/Sources/Stores/ContentStore.swift` | Modify | Load shrines array; map `.shrine` folder |
| `app/Sources/Views/QuestDetail/QuestDetailView.swift` | Modify | Type-aware complete button label |
| `app/Sources/Views/Shrines/ShrinesTabView.swift` | Create | Shrine list with completion + navigation |
| `app/Sources/Views/RootTabView.swift` | Modify | Add Shrines tab |
| `app/Sources/Views/ProgressTab/ProgressTabView.swift` | Modify | Add Shrines completion section |
| `app/Tests/Fixtures/quest-order.json` | No change | Unchanged (shrines live in separate index) |
| `app/Tests/Fixtures/shrines/index.json` | Create | Test fixture shrine index |
| `app/Tests/Fixtures/shrines/test-shrine/content.md` | Create | Test fixture shrine content |
| `app/Tests/ContentStoreTests.swift` | Modify | Add shrine load + path tests |
| `app/Tests/SnapshotTests.swift` | Modify | Add ShrinesTabView snapshot |
| `app/Resources/Content/shrines/index.json` | Regenerate | Re-run scraper to get all 5 shrines in order |

---

### Task 1: Add `.shrine` to `QuestType` and test fixtures

**Files:**
- Modify: `app/Sources/Models/Quest.swift`
- Create: `app/Tests/Fixtures/shrines/index.json`
- Create: `app/Tests/Fixtures/shrines/test-shrine/content.md`
- Modify: `app/Tests/ContentStoreTests.swift`

- [ ] **Step 1: Add the test fixture shrine index**

Create `app/Tests/Fixtures/shrines/index.json`:
```json
{
  "quests": [
    { "slug": "test-shrine", "title": "Test Shrine", "type": "shrine" }
  ],
  "sideQuests": []
}
```

- [ ] **Step 2: Add the test fixture shrine content**

Create `app/Tests/Fixtures/shrines/test-shrine/content.md`:
```
Enter the shrine.

Grab the chest.
```

- [ ] **Step 3: Write the failing test for `.shrine` QuestType decoding**

Add to `app/Tests/ContentStoreTests.swift` (inside the class body, after the existing tests):
```swift
func test_questType_shrine_decodesCorrectly() throws {
    let json = #"{"slug":"s","title":"S","type":"shrine"}"#
    let quest = try JSONDecoder().decode(Quest.self, from: Data(json.utf8))
    XCTAssertEqual(quest.type, .shrine)
}
```

- [ ] **Step 4: Run the test to verify it fails**

```bash
cd "app" && xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TOTKWalkthroughTests/ContentStoreTests/test_questType_shrine_decodesCorrectly 2>&1 | tail -20
```
Expected: FAIL — `QuestType` has no `shrine` case so decoding throws.

- [ ] **Step 5: Add `.shrine` to `QuestType`**

In `app/Sources/Models/Quest.swift`, change:
```swift
enum QuestType: String, Codable {
    case main
    case side
}
```
to:
```swift
enum QuestType: String, Codable {
    case main
    case side
    case shrine
}
```

- [ ] **Step 6: Run the test to verify it passes**

```bash
cd "app" && xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TOTKWalkthroughTests/ContentStoreTests/test_questType_shrine_decodesCorrectly 2>&1 | tail -20
```
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add app/Sources/Models/Quest.swift \
        app/Tests/ContentStoreTests.swift \
        "app/Tests/Fixtures/shrines/index.json" \
        "app/Tests/Fixtures/shrines/test-shrine/content.md"
git commit -m "feat: add QuestType.shrine and shrine test fixtures"
```

---

### Task 2: Extend `ContentStore` to load shrines

**Files:**
- Modify: `app/Sources/ModelConfig.swift`
- Modify: `app/Sources/Stores/ContentStore.swift`
- Modify: `app/Tests/ContentStoreTests.swift`

- [ ] **Step 1: Write the failing test for shrine loading**

Add to `app/Tests/ContentStoreTests.swift`:
```swift
func test_load_populatesShrines() async throws {
    let store = ContentStore(contentURL: fixturesURL)
    try await store.load()
    XCTAssertEqual(store.shrines.count, 1)
    XCTAssertEqual(store.shrines[0].slug, "test-shrine")
}

func test_contentBlocks_returnsBlocksForShrine() async throws {
    let store = ContentStore(contentURL: fixturesURL)
    try await store.load()
    let shrine = store.shrines[0]
    let blocks = try store.contentBlocks(for: shrine)
    XCTAssertFalse(blocks.isEmpty)
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd "app" && xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TOTKWalkthroughTests/ContentStoreTests/test_load_populatesShrines -only-testing:TOTKWalkthroughTests/ContentStoreTests/test_contentBlocks_returnsBlocksForShrine 2>&1 | tail -20
```
Expected: FAIL — `ContentStore` has no `shrines` property.

- [ ] **Step 3: Add `shrinesIndexPath` to ModelConfig**

In `app/Sources/ModelConfig.swift`, add one line:
```swift
enum ModelConfig {
    static let contentBundlePath = "Content"
    static let questOrderFilename = "quest-order.json"
    static let shrinesIndexPath = "shrines/index.json"
    static let progressBookmarkKey = "com.totk.bookmark"
    static let progressQuestsKey = "com.totk.quests"
}
```

- [ ] **Step 4: Update `ContentStore`**

Replace the entire contents of `app/Sources/Stores/ContentStore.swift` with:
```swift
// ContentStore.swift — Loads quest-order.json, shrines/index.json, and quest content from the app bundle.
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

    let contentURL: URL

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
        let orderData = try Data(contentsOf: orderURL)
        let order = try JSONDecoder().decode(QuestOrder.self, from: orderData)
        quests = order.quests
        sideQuests = order.sideQuests

        let shrinesURL = contentURL.appendingPathComponent(ModelConfig.shrinesIndexPath)
        if FileManager.default.fileExists(atPath: shrinesURL.path) {
            let shrinesData = try Data(contentsOf: shrinesURL)
            let shrineOrder = try JSONDecoder().decode(QuestOrder.self, from: shrinesData)
            shrines = shrineOrder.quests
        }
    }

    func contentBlocks(for quest: Quest) throws -> [ContentBlock] {
        let folder: String
        switch quest.type {
        case .main: folder = "quests"
        case .side: folder = "side-quests"
        case .shrine: folder = "shrines"
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
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd "app" && xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TOTKWalkthroughTests/ContentStoreTests 2>&1 | tail -20
```
Expected: All ContentStoreTests PASS

- [ ] **Step 6: Commit**

```bash
git add app/Sources/ModelConfig.swift \
        app/Sources/Stores/ContentStore.swift \
        app/Tests/ContentStoreTests.swift
git commit -m "feat: load shrines from shrines/index.json in ContentStore"
```

---

### Task 3: Type-aware complete button in `QuestDetailView`

**Files:**
- Modify: `app/Sources/Views/QuestDetail/QuestDetailView.swift`

- [ ] **Step 1: Update the complete button label**

In `app/Sources/Views/QuestDetail/QuestDetailView.swift`, replace the `completeButton` computed property:
```swift
@ViewBuilder
private var completeButton: some View {
    let isComplete = progressStore.isQuestComplete(quest.slug)
    let actionLabel = quest.type == .shrine ? "Mark Shrine Complete" : "Mark Quest Complete"
    Button {
        progressStore.toggleQuest(quest.slug)
    } label: {
        HStack(spacing: 8) {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
            }
            Text(isComplete ? "Completed" : actionLabel)
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
```

- [ ] **Step 2: Build to verify it compiles**

```bash
cd "app" && xcodebuild build -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/QuestDetail/QuestDetailView.swift
git commit -m "feat: type-aware complete button label in QuestDetailView"
```

---

### Task 4: Create `ShrinesTabView`

**Files:**
- Create: `app/Sources/Views/Shrines/ShrinesTabView.swift`

- [ ] **Step 1: Create the file**

Create `app/Sources/Views/Shrines/ShrinesTabView.swift`:
```swift
// ShrinesTabView.swift — Shrine list with completion tracking and detail navigation.
import SwiftUI

struct ShrinesTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    private var completionFraction: Double {
        let total = contentStore.shrines.count
        guard total > 0 else { return 0 }
        let done = contentStore.shrines.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Shrine Progress")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(themeManager.colors.primaryText)
                            Spacer()
                            Text("\(Int(completionFraction * Double(contentStore.shrines.count))) / \(contentStore.shrines.count)")
                                .font(.subheadline)
                                .foregroundStyle(themeManager.colors.accent)
                        }
                        ProgressView(value: completionFraction)
                            .tint(themeManager.colors.progressFill)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(themeManager.colors.cardBackground)
                }

                Section {
                    ForEach(contentStore.shrines) { shrine in
                        HStack(spacing: 12) {
                            Button {
                                progressStore.toggleQuest(shrine.slug)
                            } label: {
                                Image(systemName: progressStore.isQuestComplete(shrine.slug) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(progressStore.isQuestComplete(shrine.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                            }
                            .buttonStyle(.plain)

                            NavigationLink(destination: QuestDetailView(quest: shrine)) {
                                Text(shrine.title)
                                    .foregroundStyle(progressStore.isQuestComplete(shrine.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                    .strikethrough(progressStore.isQuestComplete(shrine.slug))
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                progressStore.toggleQuest(shrine.slug)
                            } label: {
                                Label(
                                    progressStore.isQuestComplete(shrine.slug) ? "Undo" : "Done",
                                    systemImage: progressStore.isQuestComplete(shrine.slug) ? "arrow.uturn.backward" : "checkmark"
                                )
                            }
                            .tint(progressStore.isQuestComplete(shrine.slug) ? .gray : .green)
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Shrine Order")
                        .foregroundStyle(themeManager.colors.sectionLabel)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shrines")
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

- [ ] **Step 2: Build to verify it compiles**

```bash
cd "app" && xcodebuild build -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10
```
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add "app/Sources/Views/Shrines/ShrinesTabView.swift"
git commit -m "feat: add ShrinesTabView"
```

---

### Task 5: Wire Shrines tab into `RootTabView` and `ProgressTabView`

**Files:**
- Modify: `app/Sources/Views/RootTabView.swift`
- Modify: `app/Sources/Views/ProgressTab/ProgressTabView.swift`

- [ ] **Step 1: Add Shrines tab to `RootTabView`**

Replace the entire contents of `app/Sources/Views/RootTabView.swift` with:
```swift
// RootTabView.swift — Root 5-tab navigation container.
import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView {
            WalkthroughTabView()
                .tabItem {
                    Label("Walkthrough", systemImage: "map")
                }
            QuestsTabView()
                .tabItem {
                    Label("Quests", systemImage: "sword")
                }
            SideQuestsTabView()
                .tabItem {
                    Label("Side Quests", systemImage: "star")
                }
            ShrinesTabView()
                .tabItem {
                    Label("Shrines", systemImage: "diamond")
                }
            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
        }
        .tint(themeManager.colors.tabActive)
    }
}
```

- [ ] **Step 2: Add Shrines section to `ProgressTabView`**

In `app/Sources/Views/ProgressTab/ProgressTabView.swift`, add a `completedShrineCount` computed property after `completedSideCount`:
```swift
private var completedShrineCount: Int {
    contentStore.shrines.filter { progressStore.isQuestComplete($0.slug) }.count
}
```

Then add the Shrines section after the Side Quests section (before the Reset section):
```swift
Section {
    LabeledContent("Completed", value: "\(completedShrineCount) / \(contentStore.shrines.count)")
        .foregroundStyle(themeManager.colors.primaryText)
        .listRowBackground(themeManager.colors.cardBackground)
    if contentStore.shrines.count > 0 {
        ProgressView(value: Double(completedShrineCount), total: Double(contentStore.shrines.count))
            .tint(themeManager.colors.progressFill)
            .listRowBackground(themeManager.colors.cardBackground)
    }
} header: {
    Text("Shrines").foregroundStyle(themeManager.colors.sectionLabel)
}
```

- [ ] **Step 3: Build to verify it compiles**

```bash
cd "app" && xcodebuild build -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10
```
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add app/Sources/Views/RootTabView.swift \
        app/Sources/Views/ProgressTab/ProgressTabView.swift
git commit -m "feat: wire ShrinesTabView into RootTabView and ProgressTabView"
```

---

### Task 6: Add shrine snapshot test

**Files:**
- Modify: `app/Tests/SnapshotTests.swift`

- [ ] **Step 1: Add the snapshot test**

Add to `app/Tests/SnapshotTests.swift` (after `test_questDetail_snapshot`):
```swift
func test_shrinesTab_snapshot() async throws {
    try await contentStore.load()
    snapshotView(ShrinesTabView(), named: "ShrinesTab")
}
```

- [ ] **Step 2: Run all snapshot tests in record mode to regenerate baselines**

Snapshot record mode is controlled by the `record` parameter passed to `snapshotView`. The existing tests already pass `record: false` (default). Run the full test suite to generate the new snapshot baseline for ShrinesTab (CI will record it):

```bash
cd "app" && xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TOTKWalkthroughTests/SnapshotTests/test_shrinesTab_snapshot 2>&1 | tail -20
```
Expected: FAIL on first run (no baseline exists yet) — CI will record. This is expected and fine.

- [ ] **Step 3: Commit**

```bash
git add app/Tests/SnapshotTests.swift
git commit -m "test: add ShrinesTabView snapshot test"
```

---

### Task 7: Regenerate `shrines/index.json` with all 5 shrines

**Files:**
- Modify: `app/Resources/Content/shrines/index.json` (via scraper)

- [ ] **Step 1: Activate the Python environment**

```bash
cd "c:/Users/twanv/Zeldo TOTK Walkthrough Framework"
source .venv/Scripts/activate
```

- [ ] **Step 2: Run the scraper with `--limit 5`**

All 5 shrine folders already have `content.md`, so the scraper will skip downloading and just write a corrected `index.json` with all 5 entries in overview page order:

```bash
python -m scripts.scrape scripts/scrapers/shrines.yaml --limit 5
```
Expected output (order will reflect IGN overview page):
```
Fetched: https://www.ign.com/wikis/.../All_Shrine_Locations_and_Solutions
Found 152 items on index page.
Skipping ukouh-shrine (already exists)
Skipping in-isa-shrine (already exists)
Skipping gutanbac-shrine (already exists)
Skipping nachoyah-shrine (already exists)
Skipping yamiyo-shrine (already exists)
Wrote: app/Resources/Content/shrines/index.json
```

- [ ] **Step 3: Verify index.json has 5 entries**

```bash
python -c "import json; d=json.load(open('app/Resources/Content/shrines/index.json')); print(len(d['quests']), 'shrines'); [print(f'  {q[\"id\"]}. {q[\"title\"]}') for q in d['quests']]"
```
Expected: 5 shrines listed in overview page order.

- [ ] **Step 4: Commit**

```bash
git add app/Resources/Content/shrines/index.json
git commit -m "content: regenerate shrines/index.json with all 5 shrines in overview order"
```

---

### Task 8: Trigger R6 build

- [ ] **Step 1: Push the branch**

```bash
git push
```

- [ ] **Step 2: Trigger the Build IPA workflow**

```bash
gh workflow run "Build IPA" --ref feat/lazy-image-scraping
```

- [ ] **Step 3: Verify the workflow started**

```bash
gh run list --workflow="Build IPA" --limit 3
```
Expected: A new run appears with status `queued` or `in_progress`.

- [ ] **Step 4: Update the memory with R6**

After confirming the run started, note R6 in the implementation progress memory (slug: `shrines-tab`, commit will be the latest on this branch).
