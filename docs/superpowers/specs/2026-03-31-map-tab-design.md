# Map Tab Design

**Date:** 2026-03-31  
**Status:** Approved

## Overview

Add a 6th tab (Map) to the TOTK Walkthrough iOS app displaying an interactive, zoomable Hyrule map with shrine and Skyview Tower pins. Shrine pins navigate to the existing `QuestDetailView`; tower pins show a popover with name and completion toggle.

---

## Decisions

| Question | Decision |
|---|---|
| Where does map live? | New 6th tab alongside existing 5 |
| Layer switching | Segmented picker: Surface / Sky / Depths |
| Pin content | Shrines (152) + Skyview Towers (15) |
| Shrine tap | Navigate to `QuestDetailView` |
| Tower tap | Popover with name + completion toggle |
| Map image | `base_map.png` from `alshival/totk-map` |
| Rendering approach | UIKit `UIScrollView` with pin `UIButton` subviews |

---

## Section 1 — Data Pipeline

### Source data

Download from `alshival/totk-map` GitHub repo:
- `map_data/shrines.csv` — 152 entries: Shrine Name, X, Y, Height, Region, Map Layer, ActorName
- `map_data/skyview_towers.csv` — ~15 entries: tower name, X, Y, Map Layer
- `map_data/base_map.png` — Hyrule surface map image

World coordinate ranges (from CSV):
- X: approximately −4680 to +4655
- Y: approximately −3825 to +3738
- Sky and Depths layers use the same X/Y coordinate space, different Height values

### Enrichment script

`scripts/enrich_map_coords.py`:
1. Downloads `shrines.csv` and `skyview_towers.csv` from the GitHub repo (rate-limited, 1.5s delay)
2. Matches shrines to our `shrines/index.json` slugs by normalising names (lowercase, strip " Guide" suffix, slugify)
3. Logs any unmatched shrines to stderr
4. Writes `app/Resources/Content/map-locations.json`
5. Downloads `base_map.png` to `app/Resources/Content/map-base.png`

### Output format

`app/Resources/Content/map-locations.json`:
```json
[
  {
    "slug": "ukouh-shrine",
    "type": "shrine",
    "layer": "sky",
    "x": 275.0,
    "y": -913.0
  },
  {
    "slug": "akkala-skyview-tower",
    "type": "tower",
    "name": "Akkala Skyview Tower",
    "layer": "surface",
    "x": 4416.0,
    "y": 1625.0
  }
]
```

---

## Section 2 — Data Models & Stores

### `MapPin.swift` (new)

```swift
enum MapLayer: String, Codable { case surface, sky, depths }
enum PinType: String, Codable { case shrine, tower }

struct MapPin: Identifiable, Codable {
    let slug: String       // shrine slug or tower slug (slugified name)
    let type: PinType
    let layer: MapLayer
    let x: Double          // in-game world X coordinate
    let y: Double          // in-game world Y coordinate
    let name: String?      // towers only; shrines resolve name from ContentStore
    var id: String { slug }
}
```

### `MapStore.swift` (new)

- `ObservableObject` loaded at app root alongside `ContentStore` and `ProgressStore`
- Loads `map-locations.json` from bundle on `load()`
- Exposes `func pins(for layer: MapLayer) -> [MapPin]`
- `ModelConfig` gains `mapLocationsPath = "map-locations.json"` and `mapImagePath = "map-base.png"`

### `ProgressStore` additions

- `@AppStorage("com.totk.towers") var completedTowers: Set<String> = []`
- `func toggleTower(_ slug: String)` — same pattern as `toggleQuest`

---

## Section 3 — UI Components

### `MapScrollView.swift` (new, `UIViewRepresentable`)

Wraps `UIScrollView`. On `makeUIView`:
1. Load `map-base.png` via `UIImage(contentsOfFile:)` using `contentStore.contentURL`
2. Add `UIImageView` filling scroll view content (same constraint pattern as `ZoomableScrollView`)
3. For each `MapPin` in `pins`, create a `UIButton` and set its `frame.origin` using the world→pixel transform:

```swift
// constants derived from CSV coordinate ranges
let worldMinX: Double = -5000, worldMaxX: Double = 5000
let worldMinY: Double = -4000, worldMaxY: Double = 4000

func worldToPixel(x: Double, y: Double, imageSize: CGSize) -> CGPoint {
    let px = (x - worldMinX) / (worldMaxX - worldMinX) * imageSize.width
    // Y is inverted: in-game Y increases northward, image Y increases downward
    let py = (1.0 - (y - worldMinY) / (worldMaxY - worldMinY)) * imageSize.height
    return CGPoint(x: px, y: py)
}
```

Pin buttons:
- Shrine: 16pt blue circle, 40% opacity if completed
- Tower: 14pt orange diamond (rotated square), 40% opacity if completed
- Tap calls `onShrineTap(slug)` or `onTowerTap(pin)` closure

The scroll view minimumZoomScale = 0.3, maximumZoomScale = 3.0 (wider range than image viewer).

### `MapTabView.swift` (new, SwiftUI)

```
TabHeaderView("Map")
Picker(Surface / Sky / Depths)   ← segmented, @State selectedLayer
MapScrollView(
    pins: mapStore.pins(for: selectedLayer),
    completedSlugs: progressStore.completedQuests ∪ completedTowers,
    onShrineTap: { slug in navigate to QuestDetailView },
    onTowerTap: { pin in selectedTower = pin }
)
.sheet(item: $selectedTower) { pin in
    TowerPopover(pin: pin)
}
.navigationDestination(for: Quest.self) { QuestDetailView(...) }
```

### `TowerPopover.swift` (new, SwiftUI)

Simple sheet:
- Tower name (title)
- Completion toggle: "Mark Complete" / "Mark Incomplete" button backed by `ProgressStore.toggleTower`
- Dismiss button

### `RootTabView` change

Add `MapTabView` as the 6th tab with `Label("Map", systemImage: "mappin.and.ellipse")`.

### `ModelConfig` additions

```swift
static let mapLocationsPath = "map-locations.json"
static let mapImagePath = "map-base.png"
// World coordinate bounds (from CSV analysis)
static let mapWorldMinX: Double = -5000
static let mapWorldMaxX: Double = 5000
static let mapWorldMinY: Double = -4000
static let mapWorldMaxY: Double = 4000
```

---

## Out of Scope

- Adventures and Side Quest pins (no coordinate dataset available)
- Depths layer pins (shrines do not exist in Depths; only towers are there)
- Korok seeds, treasure chests, or other collectibles
- Search/filter within the map view
