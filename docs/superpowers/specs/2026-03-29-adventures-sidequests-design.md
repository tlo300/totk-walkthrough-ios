# Adventures & Side Quests — Design Spec

**Date:** 2026-03-29

## Summary

Add two new scraped content types — Side Adventures and Side Quests — to the TOTK Walkthrough app. Replace the "Quests" tab with a new "Adventures" tab. Side Quests populates the existing Side Quests tab (previously empty from the manually-curated `quest-order.json`).

---

## 1. Scraper

### New file: `scripts/scrapers/adventures.yaml`

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

### Updated: `scripts/scrapers/side-quests.yaml`

Add `title_selector` and `title_strip` fields to match the shrine pattern:

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

### `scrape.py` — no changes required for Option A

The scraper already writes `{"quests": [...], "sideQuests": []}`. `ContentStore` reads only the `quests` key from each `index.json`, so the existing format works for all content types.

### Option B fallback (only if `/Side_Adventures` returns 404)

Add a `section_heading` field to YAML. Update `collect_items()` in `scrape.py` to scope link collection to table rows below the matching section header. Use `index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/Walkthrough"` with `section_heading: "Side Adventures"`.

---

## 2. Data Model & ContentStore

### `app/Sources/Models/Quest.swift`

Add `.adventure` to `QuestType`. `QuestOrder` is unchanged — all `index.json` files use the `quests` key.

```swift
enum QuestType: String, Codable {
    case main
    case side
    case shrine
    case adventure  // new
}
```

### `app/Sources/Stores/ContentStore.swift`

Three changes:

1. Add `@Published private(set) var adventures: [Quest] = []`
2. In `load()`, load `sideQuests` from `side-quests/index.json` instead of `quest-order.json` (same pattern as shrines). The `sideQuests` field in `quest-order.json` was empty/unused.
3. In `load()`, load `adventures` from `adventures/index.json` (same pattern as shrines).
4. In `contentBlocks(for:)`, add `.adventure → "adventures"` folder routing.

Final load sources:
| Property | Source |
|---|---|
| `quests` | `quest-order.json` (main walkthrough, unchanged) |
| `sideQuests` | `side-quests/index.json` (scraped) |
| `shrines` | `shrines/index.json` (unchanged) |
| `adventures` | `adventures/index.json` (new) |

---

## 3. UI

### `app/Sources/Views/RootTabView.swift`

Replace `QuestsTabView` with `AdventuresTabView`. New tab icon: `figure.walk`.

Tab order (unchanged count):
1. Walkthrough — `map`
2. **Adventures** — `figure.walk` ← replaces Quests
3. Side Quests — `star`
4. Shrines — `diamond`
5. Progress — `chart.bar`

### New: `app/Sources/Views/AdventuresTab/AdventuresTabView.swift`

Simple list bound to `contentStore.adventures`. Same structure as `QuestsTabView`.

### Deleted: `app/Sources/Views/QuestsTab/QuestsTabView.swift` (and folder)

`QuestType.main` and `contentStore.quests` remain in the codebase (used by the Walkthrough tab) but the dedicated Quests tab is retired.

---

## Run Order

```bash
# Scrape adventures (run first to verify /Side_Adventures resolves)
python -m scripts.scrape scripts/scrapers/adventures.yaml

# Scrape side quests
python -m scripts.scrape scripts/scrapers/side-quests.yaml
```
