# Quest Completion Design

## Overview

Add quest-level completion tracking so users can tick off quests and side quests as they finish them. Three interaction points all toggle the same underlying state: a tappable circle on the overview list, a swipe action on the list row, and a complete button at the bottom of the quest detail page.

## Data Model

### ProgressStore additions

Add `completedQuests: Set<String>` (keyed by `quest.slug`) persisted to `UserDefaults` under a new key (`ModelConfig.progressQuestsKey`).

New methods:
- `isQuestComplete(_ slug: String) -> Bool`
- `toggleQuest(_ slug: String)` — inserts or removes the slug and persists

The existing `completedCheckpoints` set and checkpoint methods remain unchanged. The checkpoint cards in `QuestDetailView` keep rendering as visual markers, but the "Mark Done" button is removed from `CheckpointCard` since quest-level completion is now the source of truth.

`isQuestComplete` in `WalkthroughTabView` switches from the current "all checkpoints done" derivation to `progressStore.isQuestComplete(quest.slug)`.

A new `progressQuestsKey` string constant is added to `ModelConfig`.

## UI — Interaction Points

All three apply to both main quests (`WalkthroughTabView`) and side quests (`SideQuestsTabView`).

### 1. Tappable circle on the overview list

In `WalkthroughTabView`, the existing `Image(systemName: ...)` circle is wrapped in a `Button` that calls `progressStore.toggleQuest(quest.slug)`. The `NavigationLink` wraps only the quest title text. Both sit inside an `HStack` with `.buttonStyle(.plain)` on the button to prevent the tap bleeding into the navigation link.

In `SideQuestsTabView`, a circle button and title are added fresh (the view currently has no circle or `progressStore`). Add `@EnvironmentObject private var progressStore: ProgressStore` and restructure the row the same way as `WalkthroughTabView`.

### 2. Swipe-to-complete on the list row

`.swipeActions(edge: .leading)` on each quest row with a single action:
- Incomplete: label "Done", tint green, calls `toggleQuest`
- Complete: label "Undo", tint gray, calls `toggleQuest`

Leading-edge swipe is the iOS convention for affirmative/positive actions.

### 3. Complete button at the bottom of the quest detail page

In `QuestDetailView`, after all content blocks in the `LazyVStack`, a full-width button:
- Incomplete state: "Mark Quest Complete" — accent background, accent text
- Complete state: "Completed" with a checkmark — muted/secondary styling

Tapping either state calls `progressStore.toggleQuest(quest.slug)` (allows un-completing).

## Checkpoint Card Simplification

Remove the `if !progressStore.isCheckpointComplete(id)` button block from `CheckpointCard`. The circle indicator and label remain as visual structure markers in the walkthrough content. The `isCheckpointComplete`, `markCheckpoint`, and `completedCheckpoints` members of `ProgressStore` can be deleted since nothing reads or writes them anymore.

## Files Changed

| File | Change |
|------|--------|
| `ModelConfig.swift` | Add `progressQuestsKey` constant |
| `ProgressStore.swift` | Add `completedQuests`, `isQuestComplete`, `toggleQuest`; remove checkpoint members |
| `CheckpointCard.swift` | Remove "Mark Done" button |
| `WalkthroughTabView.swift` | Tappable circle + swipe action; use `isQuestComplete` |
| `SideQuestsTabView.swift` | Same row changes as WalkthroughTabView |
| `QuestDetailView.swift` | Add complete button after content blocks |
| `ProgressStoreTests.swift` | Update tests for new API; remove checkpoint tests |
