# Shrines Tab — Design Spec

Date: 2026-03-29

## Overview

Add a Shrines tab to the TOTK Walkthrough iOS app. Each shrine entry links to a detail page (reusing `QuestDetailView`) showing the scraped IGN walkthrough content. Shrines are listed in the order they appear on the IGN overview page. Completion state is tracked the same way as quests.

## Data Layer

### `QuestType` (Quest.swift)
Add `case shrine` to the existing `QuestType` enum. The raw value `"shrine"` matches what the scraper writes to `index.json`.

### `ModelConfig` (ModelConfig.swift)
Add:
```swift
static let shrinesIndexPath = "shrines/index.json"
```

### `ContentStore` (ContentStore.swift)
- Add `@Published private(set) var shrines: [Quest] = []`
- In `load()`, read `Content/shrines/index.json` and populate `shrines` from `order.quests`
- In `contentBlocks(for:)`, extend the folder mapping: `.shrine → "shrines"`

### Content: `shrines/index.json`
Re-run scraper with `--limit 5` to regenerate the index with all 5 already-scraped shrines in overview page order. The scraper skips folders with existing `content.md` and writes correct positional IDs.

## UI Layer

### `ShrinesTabView.swift` (new file)
Mirrors `WalkthroughTabView` exactly:
- Navigation stack with "Shrines" title (Hylia font + accent color)
- Progress header section: fraction label + `ProgressView`
- List section "Shrine Order": each row has completion circle button + `NavigationLink` to `QuestDetailView(quest:)`
- Left swipe: Done / Undo action
- Gear button → `SettingsSheet`

No bookmark card (shrines have no checkpoints tracked at the list level).

### `RootTabView.swift`
Add `ShrinesTabView` as the 4th tab (between Side Quests and Progress) with label "Shrines" and `systemImage: "diamond"`.

### `ProgressTabView.swift`
Add a "Shrines" section below "Side Quests" showing completed count / total and a `ProgressView`.

### `QuestDetailView.swift`
Make the complete button label type-aware:
- `.shrine` → "Mark Shrine Complete" / "Completed"
- all others → "Mark Quest Complete" / "Completed"

## Content Pipeline

```bash
python -m scripts.scrape scripts/scrapers/shrines.yaml --limit 5
```

This regenerates `app/Resources/Content/shrines/index.json` with all 5 shrines in overview page order.

## Build

R6 — trigger Build IPA workflow after committing all changes.
