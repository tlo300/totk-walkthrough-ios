# R10: Regional Grouping, Completion Parity & Compact Nav

## Summary

Five changes shipping together as R10:

1. **Adventures tab** — wire up completion dots + swipe-to-complete (parity with Side Quests) and add progress bar (parity with Shrines)
2. **Side Quests tab** — add progress bar
3. **Regional sections** — Adventures, Side Quests, and Shrines all group items into per-region `Section`s instead of one flat list
4. **Compact nav bar** — replace the tall system navigation bar on all list tabs with a custom slim header
5. **Release bump** — build number incremented to R10

---

## Data model changes

### `Quest.region: String?`

Add an optional `region` field to the `Quest` struct. Optional so existing main-quest entries (which have no region) keep decoding cleanly.

```swift
struct Quest: Identifiable, Codable, Hashable {
    let slug: String
    let title: String
    let type: QuestType
    let region: String?   // new — nil for main quests
}
```

### JSON index files

Add `"region": "<name>"` to every entry in:
- `app/Resources/Content/shrines/index.json` (156 entries)
- `app/Resources/Content/adventures/index.json` (67 entries)
- `app/Resources/Content/side-quests/index.json` (all entries)

Also update `app/Tests/Fixtures/shrines/index.json` to stay in sync.

**Regions used** (surface only, consistent naming):

| Key | Display |
|-----|---------|
| `"Great Sky Island"` | Great Sky Island |
| `"Central Hyrule"` | Central Hyrule |
| `"Eldin"` | Eldin |
| `"Akkala"` | Akkala |
| `"Hebra"` | Hebra |
| `"Lanayru"` | Lanayru |
| `"Necluda"` | Necluda |
| `"Faron"` | Faron |
| `"Gerudo"` | Gerudo |

Ordering in views follows the list above (GSI → Central → clockwise roughly).

---

## View changes

### Compact custom header (all list tabs)

**Replace** the `NavigationStack` built-in toolbar with:
- `.toolbar(.hidden, for: .navigationBar)` on the list view
- A custom `HStack` pinned above the `List` containing: centered title (same font/color as before) + trailing gear button

When the user taps a row and navigates into `QuestDetailView`, the system nav bar reappears automatically with the back button — this is the standard SwiftUI behaviour when only the parent view hides the bar.

The custom header height is controlled by its content padding (~8pt vertical), targeting roughly 36–40pt total — noticeably slimmer than the system 44pt bar.

### Adventures tab

- Add `@EnvironmentObject private var progressStore: ProgressStore`
- Add progress card section (same layout as Shrines)
- Add circle toggle button + strikethrough text + swipe action (same as SideQuestsTabView)
- Replace flat `List(contentStore.adventures)` with region-grouped sections (see below)

### Side Quests tab

- Add progress card section
- Replace flat `ForEach` with region-grouped sections

### Shrines tab

- Replace the single `"Shrine Order"` section with region-grouped sections
- Keep existing progress card section at top

### Regional section pattern (shared)

All three tabs use the same grouping approach:

```swift
let regionOrder = ["Great Sky Island", "Central Hyrule", "Eldin", "Akkala",
                   "Hebra", "Lanayru", "Necluda", "Faron", "Gerudo"]
let grouped = Dictionary(grouping: items) { $0.region ?? "Other" }

ForEach(regionOrder, id: \.self) { region in
    if let quests = grouped[region], !quests.isEmpty {
        Section(header: Text(region)...) {
            ForEach(quests) { ... }
        }
    }
}
```

Section headers use `themeManager.colors.sectionLabel` (same as existing headers).

---

## Build / release

- Bump `MARKETING_VERSION` (or equivalent) in the Xcode project to produce an artifact named R10
- IPA generated via existing `build-ipa.yml` GitHub Actions workflow
- No model or scraper changes

---

## Out of scope

- Progress tab changes (already shows per-type totals)
- Walkthrough tab (already has "Quest Order" single section — no region needed for linear main quest)
- Sky Islands (non-GSI) and Depths regions
