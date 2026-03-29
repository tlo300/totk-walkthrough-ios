# Adventures & Side Quests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scrape IGN Side Adventures and Side Quests, add an Adventures tab replacing the retired Quests tab, and wire Side Quests to its scraped index.

**Architecture:** Two new YAML scraper configs write content into `app/Resources/Content/adventures/` and `app/Resources/Content/side-quests/`. `ContentStore` loads each from its own `index.json` (same pattern as shrines). A new `AdventuresTabView` replaces `QuestsTabView` in `RootTabView`.

**Tech Stack:** Python 3 / BeautifulSoup / requests (scraper), Swift 5.9 / SwiftUI / `@MainActor` ObservableObject (app)

---

## File Map

| Action | Path |
|--------|------|
| Create | `scripts/scrapers/adventures.yaml` |
| Modify | `scripts/scrapers/side-quests.yaml` |
| Modify | `app/Sources/Models/Quest.swift` |
| Modify | `app/Sources/ModelConfig.swift` |
| Modify | `app/Sources/Stores/ContentStore.swift` |
| Create | `app/Sources/Views/AdventuresTab/AdventuresTabView.swift` |
| Modify | `app/Sources/Views/RootTabView.swift` |
| Delete | `app/Sources/Views/QuestsTab/QuestsTabView.swift` |

---

## Task 1: Scraper configs

**Files:**
- Create: `scripts/scrapers/adventures.yaml`
- Modify: `scripts/scrapers/side-quests.yaml`

- [ ] **Step 1: Create `scripts/scrapers/adventures.yaml`**

```yaml
index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/Side_Adventures"
content_type: "adventure"
output_dir: "app/Resources/Content/adventures"
item_links: "a[data-cy='styled-link']"
title_selector: ".page-header h1"
title_strip: " - Tears of the Kingdom"
content_area: "div.wiki-page-container"
delay_seconds: 1.5
```

- [ ] **Step 2: Replace `scripts/scrapers/side-quests.yaml` with the updated version**

```yaml
index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/Side_Quests"
content_type: "side-quest"
output_dir: "app/Resources/Content/side-quests"
item_links: "a[data-cy='styled-link']"
title_selector: ".page-header h1"
title_strip: " - Tears of the Kingdom"
content_area: "div.wiki-page-container"
delay_seconds: 1.5
```

- [ ] **Step 3: Verify adventures index URL resolves (--limit 1 smoke test)**

Activate the project venv first:
```bash
cd "c:/Users/twanv/Zeldo TOTK Walkthrough Framework"
.venv/Scripts/activate
python -m scripts.scrape scripts/scrapers/adventures.yaml --limit 1
```

Expected: fetches one adventure detail page, writes `app/Resources/Content/adventures/<slug>/content.md` and `app/Resources/Content/adventures/index.json`. If you see `HTTP 404` or `Found 0 items`, the `/Side_Adventures` URL doesn't exist — see **Option B fallback** below before continuing.

**Option B fallback** (only needed if Step 3 returns 0 items or 404): Change `adventures.yaml` to:

```yaml
index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/Walkthrough"
content_type: "adventure"
output_dir: "app/Resources/Content/adventures"
item_links: "table tr td:first-child a[href]"
title_selector: ".page-header h1"
title_strip: " - Tears of the Kingdom"
content_area: "div.wiki-page-container"
delay_seconds: 1.5
```

This targets only the first table cell `<a>` links within the Side Adventures table on the Walkthrough hub page. Re-run Step 3 after the change. Note: this selector may also pick up Side Quest links from the same page — inspect the printed item count vs the known ~60 adventures count to confirm. If it picks up too many, open an issue to add `section_heading` scoping to `scrape.py`.

- [ ] **Step 4: Commit**

```bash
git add scripts/scrapers/adventures.yaml scripts/scrapers/side-quests.yaml
git commit -m "feat: add adventures scraper config, update side-quests config"
```

---

## Task 2: Add `adventure` type and `ModelConfig` path constants

**Files:**
- Modify: `app/Sources/Models/Quest.swift`
- Modify: `app/Sources/ModelConfig.swift`

- [ ] **Step 1: Add `.adventure` case to `QuestType` in `app/Sources/Models/Quest.swift`**

Replace the `QuestType` enum:

```swift
enum QuestType: String, Codable {
    case main
    case side
    case shrine
    case adventure
}
```

`QuestOrder` is unchanged — leave it as-is.

- [ ] **Step 2: Add two path constants to `app/Sources/ModelConfig.swift`**

```swift
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
}
```

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Models/Quest.swift app/Sources/ModelConfig.swift
git commit -m "feat: add adventure QuestType case and index path constants"
```

---

## Task 3: Update ContentStore

**Files:**
- Modify: `app/Sources/Stores/ContentStore.swift`

- [ ] **Step 1: Replace `ContentStore.swift` with the updated version**

```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add app/Sources/Stores/ContentStore.swift
git commit -m "feat: add adventures to ContentStore, load sideQuests from scraped index"
```

---

## Task 4: Create AdventuresTabView

**Files:**
- Create: `app/Sources/Views/AdventuresTab/AdventuresTabView.swift`

- [ ] **Step 1: Create `app/Sources/Views/AdventuresTab/AdventuresTabView.swift`**

```swift
// AdventuresTabView.swift — Browsable list of all side adventures.
import SwiftUI

struct AdventuresTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List(contentStore.adventures) { quest in
                NavigationLink(destination: QuestDetailView(quest: quest)) {
                    Text(quest.title)
                        .foregroundStyle(themeManager.colors.primaryText)
                }
                .listRowBackground(themeManager.colors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Adventures")
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

- [ ] **Step 2: Commit**

```bash
git add app/Sources/Views/AdventuresTab/AdventuresTabView.swift
git commit -m "feat: add AdventuresTabView"
```

---

## Task 5: Swap Quests tab → Adventures tab

**Files:**
- Modify: `app/Sources/Views/RootTabView.swift`
- Delete: `app/Sources/Views/QuestsTab/QuestsTabView.swift`

- [ ] **Step 1: Replace `app/Sources/Views/RootTabView.swift`**

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
            AdventuresTabView()
                .tabItem {
                    Label("Adventures", systemImage: "figure.walk")
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

- [ ] **Step 2: Delete `app/Sources/Views/QuestsTab/QuestsTabView.swift`**

```bash
rm "app/Sources/Views/QuestsTab/QuestsTabView.swift"
rmdir "app/Sources/Views/QuestsTab"
```

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/RootTabView.swift
git rm app/Sources/Views/QuestsTab/QuestsTabView.swift
git commit -m "feat: replace Quests tab with Adventures tab, retire QuestsTabView"
```

---

## Task 6: Run full scrape

- [ ] **Step 1: Scrape adventures (full run)**

```bash
cd "c:/Users/twanv/Zeldo TOTK Walkthrough Framework"
.venv/Scripts/activate
python -m scripts.scrape scripts/scrapers/adventures.yaml
```

Expected: prints `Found N items`, fetches each, writes `app/Resources/Content/adventures/<slug>/content.md` and `app/Resources/Content/adventures/index.json`. Watch for `WARNING: content_area selector found nothing` — if widespread, the selector needs checking.

- [ ] **Step 2: Scrape side quests (full run)**

```bash
python -m scripts.scrape scripts/scrapers/side-quests.yaml
```

Expected: same pattern, writes into `app/Resources/Content/side-quests/`.

- [ ] **Step 3: Spot-check output**

```bash
cat app/Resources/Content/adventures/index.json | python -m json.tool | head -30
cat app/Resources/Content/side-quests/index.json | python -m json.tool | head -30
```

Confirm: `quests` array is non-empty, each entry has `id`, `slug`, `title`, `type` (`"adventure"` or `"side-quest"`).

- [ ] **Step 4: Commit scraped content**

```bash
git add app/Resources/Content/adventures/ app/Resources/Content/side-quests/
git commit -m "content: scrape side adventures and side quests from IGN"
```
