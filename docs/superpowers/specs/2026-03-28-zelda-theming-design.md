# Zelda Theming Design

**Date:** 2026-03-28
**Status:** Approved

## Overview

Add Zelda-inspired visual theming to the TOTK Walkthrough iOS app. Three themes switchable at runtime via a settings sheet, with an optional Hylia Serif font for headings. No external image assets — all styling is pure SwiftUI.

---

## Themes

Three self-contained themes, each defined by a `ThemeColors` value:

| Theme | Background | Accent | Card border | Glow |
|---|---|---|---|---|
| **Parchment & Gold** | `#f0e2c0` | `#c8a84b` | `#c8a84b` | none |
| **Zonai Dark** | `#0d1a0f` | `#2d7a3a` | `#1f5a27` | `#2d7a3a` (green) |
| **Classic Blue & Gold** | `#111d36` | `#c8a84b` | `#2a3d66` | none |

---

## Architecture

### New files

**`app/Sources/Theme/AppTheme.swift`**
Defines the `AppTheme` enum (`.parchment`, `.zonaiDark`, `.classicBlue`) and the `ThemeColors` struct with semantic named values. Each `AppTheme` case has a `var colors: ThemeColors` computed property returning hardcoded values.

Semantic color names in `ThemeColors`:
- `background` — full-screen background
- `cardBackground` — list row / card fill
- `cardBorder` — card stroke color
- `accent` — primary accent (progress bar, active checkmarks, badge background)
- `accentText` — text on accent-colored backgrounds
- `primaryText` — main content text
- `secondaryText` — muted / completed quest text
- `sectionLabel` — uppercase section header label
- `progressFill` — progress bar fill
- `tabActive` — active tab icon/label
- `tabInactive` — inactive tab icon/label
- `navBackground` — navigation bar background
- `navBorder` — navigation bar bottom border
- `checkpointDone` — completed checkpoint dot
- `checkpointPending` — incomplete checkpoint dot/border
- `glow` — optional `Color?` for Zonai card shadow; `nil` for other themes

**`app/Sources/Theme/ThemeManager.swift`**
`ThemeManager: ObservableObject`. Holds `@AppStorage("appTheme") var selectedTheme: AppTheme = .parchment` and `@AppStorage("useHyliaSerif") var useHyliaSerif: Bool = true`. Exposes `var colors: ThemeColors { selectedTheme.colors }` and `func headingFont(size: CGFloat) -> Font` which returns `.custom("HyliaSerif", size: size)` when enabled, falling back to `.system(size: size, weight: .bold)`.

**`app/Sources/Views/Settings/SettingsSheet.swift`**
SwiftUI `View` presenting the settings sheet. Contains:
- Section "App Theme" — three tappable rows (one per `AppTheme`), each showing a colour swatch emoji, name, description, and a checkmark when selected. Tapping updates `themeManager.selectedTheme`.
- Section "Typography" — a `Toggle` for `themeManager.useHyliaSerif`.

**`app/Sources/Resources/Fonts/HyliaSerif.otf`**
Fan-made Hylia Serif font file. Must be manually downloaded and placed here before building. License: personal/fan use only (not for commercial App Store distribution — compatible with SideStore sideloading).

### Modified files

**`app/Sources/Views/TOTKWalkthroughApp.swift`**
Instantiate `ThemeManager` as a `@StateObject` and inject into the environment with `.environmentObject(themeManager)`. Apply `themeManager.colors.background` as the app's background color.

**`app/Sources/Views/RootTabView.swift`**
Add `@EnvironmentObject var themeManager: ThemeManager`. Apply `themeManager.colors.tabActive` to the `TabView` via `.tint`.

**`app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift`**
- Each tab manages its own `@State var showingSettings = false` with a `.sheet(isPresented:) { SettingsSheet() }`.
- Navigation title: use `ToolbarItem(placement: .principal)` with `Text("Walkthrough").font(themeManager.headingFont(size: 20))` instead of `.navigationTitle`. Remove `.navigationBarTitleDisplayMode`.
- Progress bar: `.tint(themeManager.colors.progressFill)`
- Quest rows: text colors use `themeManager.colors.primaryText` / `secondaryText`, strikethrough on completed
- Gear toolbar button: `ToolbarItem(placement: .navigationBarTrailing)` with `Button { showingSettings = true } label: { Image(systemName: "gearshape").foregroundColor(themeManager.colors.accent) }`

**`app/Sources/Views/QuestsTab/QuestsTabView.swift`**
Same pattern: own `@State var showingSettings`, principal toolbar title, gear button. List rows use `themeManager.colors.primaryText`.

**`app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift`**
Same pattern: own `@State var showingSettings`, principal toolbar title, gear button, color wiring.

**`app/Sources/Views/ProgressTab/ProgressTabView.swift`**
Same pattern: own `@State var showingSettings`, principal toolbar title, gear button. Progress bar tint and label colors wired to theme.

**`app/Sources/Views/QuestDetail/QuestDetailView.swift`**
- Navigation title: `ToolbarItem(placement: .principal)` with `Text(quest.title).font(themeManager.headingFont(size: 18))`
- Text blocks: `themeManager.colors.primaryText`
- Images: `clipShape(RoundedRectangle)` with `strokeBorder(themeManager.colors.cardBorder)`

**`app/Sources/Views/QuestDetail/CheckpointCard.swift`**
- Card background: `themeManager.colors.cardBackground`
- Card border: `themeManager.colors.cardBorder` (+ optional `.shadow(color: themeManager.colors.glow ?? .clear, radius: 4)` for Zonai)
- Done dot: `themeManager.colors.checkpointDone`
- Pending dot/ring: `themeManager.colors.checkpointPending`
- "Mark Done" button: `themeManager.colors.accent` background, `themeManager.colors.accentText` text

**`app/Sources/Views/WalkthroughTab/BookmarkCard.swift`**
Same card styling as `CheckpointCard`.

**`app/Package.swift`**
Add `HyliaSerif.otf` to the resources for the app target so it is included in the bundle.

**`app/Info.plist`** (or `app/Sources/Info.plist`)
Add `UIAppFonts` array with entry `HyliaSerif.otf` so UIKit/SwiftUI can register the font.

---

## Font setup

Hylia Serif is a fan-made font, not bundled here. To set it up:
1. Download `HyliaSerif.otf` from a fan font site (e.g. search "Hylia Serif font").
2. Drop it into `app/Sources/Resources/Fonts/`.
3. The `Package.swift` and `Info.plist` changes handle the rest.

The `useHyliaSerif` toggle defaults to `true`. If the font file is missing, `UIFont(name:size:)` returns nil and SwiftUI silently falls back to the system font — so the app won't crash if the font is absent.

---

## Out of scope

- Custom tab bar icons (uses SF Symbols)
- Image assets from itch.io (all styling is pure SwiftUI)
- Light/dark mode interaction (themes are independent of system appearance)
- Per-tab theme overrides

---

## Open questions (none — all resolved)

- Entry point: gear icon in every tab's nav bar ✓
- Architecture: ThemeManager + @AppStorage + Environment ✓
- Font: Hylia Serif for headings only, toggle in settings ✓
