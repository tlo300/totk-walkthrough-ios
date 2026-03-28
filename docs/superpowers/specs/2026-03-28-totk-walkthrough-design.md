# TOTK Walkthrough iOS App — Design Spec

**Date:** 2026-03-28
**Status:** Approved

---

## Overview

An iPhone app that guides players through Zelda: Tears of the Kingdom. It provides a linear walkthrough as its primary path, but allows users to jump to any quest directly. Progress is tracked per-step with a persistent bookmark.

---

## Content Pipeline

### Source documents (local only, gitignored)

| File | Purpose |
|------|---------|
| `content/quest-order.docx` | Master list defining the order of all main quests |
| `content/quests/<name>.docx` | One Word doc per main quest with rich text and embedded images |
| `content/side-quests/<name>.docx` | One Word doc per side quest (same format) |

### Quest order document format

`quest-order.docx` is a simple numbered list where each item is the exact quest title (e.g. `1. Find Princess Zelda`). The script slugifies each title (lowercase, spaces to hyphens) to derive the corresponding `.docx` filename and the slug used in `quest-order.json`. Quest `.docx` filenames must match this slugified form exactly.

### Conversion script

A local Python script at `scripts/convert.py` processes the Word docs:

- Parses `quest-order.docx` → `app/Resources/Content/quest-order.json`
- Converts each quest doc → `app/Resources/Content/quests/<slug>/content.md` + extracted images saved as `app/Resources/Content/quests/<slug>/<image>.png`
- Converts each side quest doc → same structure under `app/Resources/Content/side-quests/`

**Checkpoint markers** are defined in the Word docs using a simple convention (e.g. a specially styled paragraph or a bookmark tag). The script detects these and emits them as a distinct element in the Markdown (e.g. `<!-- checkpoint: id -->` comment or a custom fenced block).

The generated `app/Resources/Content/` folder is committed to GitHub. The raw `.docx` files are never committed.

### `quest-order.json` schema

```json
{
  "quests": [
    { "slug": "find-princess-zelda", "title": "Find Princess Zelda", "type": "main" },
    { "slug": "visit-purahs-lab",    "title": "Visit Purah's Lab",    "type": "main" }
  ],
  "sideQuests": [
    { "slug": "stables-of-hyrule", "title": "Stables of Hyrule", "type": "side" }
  ]
}
```

### Checkpoint convention in Word docs

Checkpoints are paragraphs with a specific Word style named `Checkpoint`. The script converts each one to a fenced block in Markdown:

```
~~~checkpoint
id: reached-castle-gates
label: Reached the castle gates?
~~~
```

---

## iOS App Architecture

**Language:** Swift 5.9+
**UI:** SwiftUI only
**Concurrency:** async/await throughout
**Minimum deployment target:** iOS 18
**Dependencies:** `swift-snapshot-testing` (test target only)

### Modules

| Module | Responsibility |
|--------|---------------|
| `ContentStore` | Loads and parses `quest-order.json` + Markdown files from the app bundle at launch. Exposes typed `Quest` and `SideQuest` models. Read-only. |
| `ProgressStore` | Persists and exposes completion state: which checkpoint IDs are checked, and the current bookmark (active quest slug + checkpoint index). Backed by `UserDefaults`. |
| `QuestContentParser` | Parses a quest's `content.md` into a list of typed content blocks: `.text(AttributedString)`, `.image(String)`, `.checkpoint(id:label:)`. |
| Views | SwiftUI views — no business logic. |

### Tab bar (4 tabs)

| Tab | Content |
|-----|---------|
| Walkthrough | Linear quest list. Shows overall progress bar, "Currently On" bookmark card, and the full ordered list with per-quest completion state. Tapping a quest opens the quest detail view. |
| Quests | Browsable list of all main quests. Tapping opens quest detail. |
| Side Quests | Browsable list of all side quests. Same detail view. |
| Progress | Overall completion percentage, counts per category, and a reset option. |

### Quest detail view

A `ScrollView` rendering the quest's content blocks in order:

- `.text` blocks → `Text(attributedString)` (SwiftUI native Markdown rendering)
- `.image` blocks → `Image(named:)` loaded from the bundle
- `.checkpoint` blocks → a card showing the checkpoint label with a "Mark Done" button. Tapping calls `ProgressStore.markCheckpoint(id:)`. Completed checkpoints show a green check.

The nav bar shows the quest title and a back button returning to the originating tab.

### `ModelConfig.swift`

All tuneable values live here:

```swift
enum ModelConfig {
    static let contentBundlePath = "Content"
    static let questOrderFilename = "quest-order.json"
    static let progressStoreKey = "com.totk.progress"
}
```

---

## Testing Strategy

### Content pipeline (Windows, local)

- `pytest` unit tests in `scripts/tests/`
- Tests use sample `.docx` fixtures (small, synthetic — no real walkthrough content)
- Validates: quest order parsing, Markdown output structure, image extraction, checkpoint detection
- Run in VSCode terminal: `python -m pytest scripts/tests/`

### iOS app (GitHub Actions, macOS-14 runner)

**`test.yml` workflow** — triggers on every push:

1. Build the app for the iOS Simulator
2. Run `XCTest` unit tests for `ContentStore`, `ProgressStore`, `QuestContentParser`
3. Run SwiftUI snapshot tests (via `swift-snapshot-testing`) for all major screens
4. Upload PNG snapshots as a CI artifact — reviewable in the GitHub Actions UI without needing Xcode or a Mac

**`build-ipa.yml` workflow** — triggered manually:

1. Build a release `.ipa` (unsigned)
2. Upload as artifact for SideStore sideloading

---

## File Layout

```
app/
  Resources/
    Content/
      quest-order.json
      quests/
        find-princess-zelda/
          content.md
          image-001.png
          image-002.png
      side-quests/
        stables-of-hyrule/
          content.md
  Sources/
    Models/
      Quest.swift
      ContentBlock.swift
    Stores/
      ContentStore.swift
      ProgressStore.swift
    Parsing/
      QuestContentParser.swift
    Views/
      WalkthroughTab/
      QuestsTab/
      SideQuestsTab/
      ProgressTab/
      QuestDetailView.swift
    ModelConfig.swift
scripts/
  convert.py
  tests/
    test_convert.py
    fixtures/
.github/
  workflows/
    test.yml
    build-ipa.yml
```

---

## Out of Scope

- Search / filtering
- iCloud sync across devices
- Notifications or reminders
- iPad layout
- In-app content updates (content changes require a new build)
