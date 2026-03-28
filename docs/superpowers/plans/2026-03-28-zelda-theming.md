# Zelda Theming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three switchable Zelda-inspired themes (Parchment & Gold, Zonai Dark, Classic Blue & Gold) with a gear-icon settings sheet accessible from every tab, and an optional Hylia Serif font for headings.

**Architecture:** A `ThemeManager` `ObservableObject` holding `@AppStorage`-backed theme selection is injected as an environment object at the app root. All views read semantic colors (`themeManager.colors.X`) instead of hardcoded values. `SettingsSheet` opens from a gear toolbar button in every tab's `NavigationStack`.

**Tech Stack:** Swift 5.9, SwiftUI, `@AppStorage`, XcodeGen (`project.yml`), swift-snapshot-testing 1.17.0.

---

## File Map

**New files:**
- `app/Sources/Theme/AppTheme.swift` — `AppTheme` enum, `ThemeColors` struct, all colour values
- `app/Sources/Theme/ThemeManager.swift` — `ObservableObject` wrapper with `@AppStorage`, font helper
- `app/Sources/Views/Settings/SettingsSheet.swift` — theme picker + Hylia Serif toggle sheet
- `app/Sources/Resources/Fonts/HyliaSerif.otf` — font file (manual download, not committed)
- `app/Tests/ThemeTests.swift` — unit tests for `AppTheme` and `ThemeManager`

**Modified files:**
- `project.yml` — add `UIAppFonts` key
- `app/Sources/Views/TOTKWalkthroughApp.swift` — inject `ThemeManager` into environment
- `app/Sources/Views/RootTabView.swift` — tab tint from theme
- `app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift` — full theming + gear button
- `app/Sources/Views/QuestsTab/QuestsTabView.swift` — full theming + gear button
- `app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift` — full theming + gear button
- `app/Sources/Views/ProgressTab/ProgressTabView.swift` — full theming + gear button
- `app/Sources/Views/QuestDetail/QuestDetailView.swift` — full theming
- `app/Sources/Views/QuestDetail/CheckpointCard.swift` — card colours from theme
- `app/Sources/Views/WalkthroughTab/BookmarkCard.swift` — card colours from theme
- `app/Tests/SnapshotTests.swift` — inject `ThemeManager` into snapshot helper

---

## Task 1: AppTheme + ThemeColors

**Files:**
- Create: `app/Sources/Theme/AppTheme.swift`
- Create: `app/Tests/ThemeTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `app/Tests/ThemeTests.swift`:

```swift
// ThemeTests.swift — Unit tests for AppTheme colour values.
import XCTest
import SwiftUI
@testable import TOTKWalkthrough

final class ThemeTests: XCTestCase {

    func test_allThemes_haveDistinctRawValues() {
        let rawValues = AppTheme.allCases.map { $0.rawValue }
        XCTAssertEqual(rawValues.count, Set(rawValues).count, "Each AppTheme case must have a unique rawValue")
    }

    func test_zonaiDark_hasGlow() {
        XCTAssertNotNil(AppTheme.zonaiDark.colors.glow)
    }

    func test_parchment_hasNoGlow() {
        XCTAssertNil(AppTheme.parchment.colors.glow)
    }

    func test_classicBlue_hasNoGlow() {
        XCTAssertNil(AppTheme.classicBlue.colors.glow)
    }

    func test_allThemes_haveDisplayName() {
        for theme in AppTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty)
        }
    }

    func test_appTheme_rawValue_roundtrips() {
        for theme in AppTheme.allCases {
            XCTAssertEqual(AppTheme(rawValue: theme.rawValue), theme)
        }
    }
}
```

- [ ] **Step 2: Run tests — expect compile failure (AppTheme not defined yet)**

```
xcodebuild test -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthroughTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TOTKWalkthroughTests/ThemeTests 2>&1 | tail -20
```

Expected: `error: cannot find type 'AppTheme' in scope`

- [ ] **Step 3: Create `app/Sources/Theme/AppTheme.swift`**

```swift
// AppTheme.swift — Zelda theme definitions: colours and semantic values per theme.
import SwiftUI

enum AppTheme: String, CaseIterable {
    case parchment
    case zonaiDark
    case classicBlue

    var displayName: String {
        switch self {
        case .parchment:   return "Parchment & Gold"
        case .zonaiDark:   return "Zonai Dark"
        case .classicBlue: return "Classic Blue & Gold"
        }
    }

    var description: String {
        switch self {
        case .parchment:   return "Warm map scroll aesthetic"
        case .zonaiDark:   return "Ancient tech, glowing green"
        case .classicBlue: return "Timeless Zelda menu feel"
        }
    }

    var emoji: String {
        switch self {
        case .parchment:   return "📜"
        case .zonaiDark:   return "🌿"
        case .classicBlue: return "🏰"
        }
    }

    var colors: ThemeColors {
        switch self {
        case .parchment:
            return ThemeColors(
                background:        Color(hex: "f0e2c0"),
                cardBackground:    Color(hex: "e8d5a3"),
                cardBorder:        Color(hex: "c8a84b"),
                accent:            Color(hex: "c8a84b"),
                accentText:        Color(hex: "3d2200"),
                primaryText:       Color(hex: "3d2200"),
                secondaryText:     Color(hex: "8b6914"),
                sectionLabel:      Color(hex: "8b6914"),
                progressFill:      Color(hex: "5c3d11"),
                tabActive:         Color(hex: "5c3d11"),
                tabInactive:       Color(hex: "8b6914"),
                navBackground:     Color(hex: "e8d5a3"),
                navBorder:         Color(hex: "c8a84b"),
                checkpointDone:    Color(hex: "5c3d11"),
                checkpointPending: Color(hex: "c8a84b"),
                glow:              nil
            )
        case .zonaiDark:
            return ThemeColors(
                background:        Color(hex: "0d1a0f"),
                cardBackground:    Color(hex: "112214"),
                cardBorder:        Color(hex: "1f5a27"),
                accent:            Color(hex: "2d7a3a"),
                accentText:        Color(hex: "c8f0cc"),
                primaryText:       Color(hex: "c8f0cc"),
                secondaryText:     Color(hex: "3a8a4a"),
                sectionLabel:      Color(hex: "3a8a4a"),
                progressFill:      Color(hex: "2d7a3a"),
                tabActive:         Color(hex: "6eff7f"),
                tabInactive:       Color(hex: "3a8a4a"),
                navBackground:     Color(hex: "0f1f12"),
                navBorder:         Color(hex: "2d7a3a"),
                checkpointDone:    Color(hex: "6eff7f"),
                checkpointPending: Color(hex: "2d7a3a"),
                glow:              Color(hex: "2d7a3a")
            )
        case .classicBlue:
            return ThemeColors(
                background:        Color(hex: "111d36"),
                cardBackground:    Color(hex: "1a2744"),
                cardBorder:        Color(hex: "2a3d66"),
                accent:            Color(hex: "c8a84b"),
                accentText:        Color(hex: "0d1628"),
                primaryText:       Color(hex: "d0dcf0"),
                secondaryText:     Color(hex: "6a8acc"),
                sectionLabel:      Color(hex: "6a8acc"),
                progressFill:      Color(hex: "c8a84b"),
                tabActive:         Color(hex: "f0d060"),
                tabInactive:       Color(hex: "4a6aaa"),
                navBackground:     Color(hex: "1a2744"),
                navBorder:         Color(hex: "c8a84b"),
                checkpointDone:    Color(hex: "f0d060"),
                checkpointPending: Color(hex: "c8a84b"),
                glow:              nil
            )
        }
    }
}

struct ThemeColors {
    let background: Color
    let cardBackground: Color
    let cardBorder: Color
    let accent: Color
    let accentText: Color
    let primaryText: Color
    let secondaryText: Color
    let sectionLabel: Color
    let progressFill: Color
    let tabActive: Color
    let tabInactive: Color
    let navBackground: Color
    let navBorder: Color
    let checkpointDone: Color
    let checkpointPending: Color
    let glow: Color?
}

extension Color {
    init(hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
xcodebuild test -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthroughTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TOTKWalkthroughTests/ThemeTests 2>&1 | tail -20
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add app/Sources/Theme/AppTheme.swift app/Tests/ThemeTests.swift
git commit -m "feat: add AppTheme enum and ThemeColors struct"
```

---

## Task 2: ThemeManager

**Files:**
- Create: `app/Sources/Theme/ThemeManager.swift`
- Modify: `app/Tests/ThemeTests.swift`

- [ ] **Step 1: Add ThemeManager tests to `app/Tests/ThemeTests.swift`**

Append to the file (after the closing brace of `ThemeTests`):

```swift
final class ThemeManagerTests: XCTestCase {

    func test_defaultTheme_isParchment() {
        let manager = ThemeManager()
        XCTAssertEqual(manager.selectedTheme, .parchment)
    }

    func test_colors_matchesSelectedTheme() {
        let manager = ThemeManager()
        manager.selectedTheme = .zonaiDark
        XCTAssertNotNil(manager.colors.glow, "Zonai Dark must have a glow colour")
    }

    func test_headingFont_withSerif_returnsCustomFont() {
        let manager = ThemeManager()
        manager.useHyliaSerif = true
        let font = manager.headingFont(size: 20)
        // Font description contains the custom name when the font exists,
        // or falls back silently — either way it must not crash
        XCTAssertNotNil(font)
    }

    func test_headingFont_withoutSerif_returnsSystemFont() {
        let manager = ThemeManager()
        manager.useHyliaSerif = false
        let font = manager.headingFont(size: 20)
        XCTAssertNotNil(font)
    }
}
```

- [ ] **Step 2: Run — expect compile failure (ThemeManager not defined)**

```
xcodebuild test -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthroughTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TOTKWalkthroughTests/ThemeManagerTests 2>&1 | tail -10
```

Expected: `error: cannot find type 'ThemeManager' in scope`

- [ ] **Step 3: Create `app/Sources/Theme/ThemeManager.swift`**

```swift
// ThemeManager.swift — Runtime theme state, persisted via @AppStorage.
import SwiftUI

final class ThemeManager: ObservableObject {
    @AppStorage("appTheme")      var selectedTheme: AppTheme = .parchment
    @AppStorage("useHyliaSerif") var useHyliaSerif: Bool = true

    var colors: ThemeColors { selectedTheme.colors }

    func headingFont(size: CGFloat) -> Font {
        guard useHyliaSerif else {
            return .system(size: size, weight: .bold)
        }
        return .custom("HyliaSerif", size: size, relativeTo: .headline)
    }
}
```

- [ ] **Step 4: Run tests — expect pass**

```
xcodebuild test -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthroughTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TOTKWalkthroughTests/ThemeManagerTests 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add app/Sources/Theme/ThemeManager.swift app/Tests/ThemeTests.swift
git commit -m "feat: add ThemeManager with @AppStorage persistence"
```

---

## Task 3: SettingsSheet

**Files:**
- Create: `app/Sources/Views/Settings/SettingsSheet.swift`

- [ ] **Step 1: Create `app/Sources/Views/Settings/SettingsSheet.swift`**

```swift
// SettingsSheet.swift — Theme picker and typography toggle, opened from any tab.
import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("App Theme") {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button {
                            themeManager.selectedTheme = theme
                        } label: {
                            HStack(spacing: 12) {
                                Text(theme.emoji)
                                    .font(.title2)
                                    .frame(width: 36, height: 36)
                                    .background(themeManager.colors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(themeManager.colors.cardBorder, lineWidth: 1)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(theme.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(themeManager.colors.primaryText)
                                    Text(theme.description)
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.secondaryText)
                                }

                                Spacer()

                                if themeManager.selectedTheme == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(themeManager.colors.accent)
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                    }
                }

                Section("Typography") {
                    Toggle(isOn: $themeManager.useHyliaSerif) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Hylia Serif headings")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(themeManager.colors.primaryText)
                            Text("Fan-made Zelda-style font")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.secondaryText)
                        }
                    }
                    .tint(themeManager.colors.accent)
                    .listRowBackground(themeManager.colors.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(themeManager.headingFont(size: 18))
                        .foregroundColor(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.colors.accent)
                }
            }
            .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

```
xcodebuild build -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthrough \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/Settings/SettingsSheet.swift
git commit -m "feat: add SettingsSheet with theme picker and font toggle"
```

---

## Task 4: Font setup

**Files:**
- Modify: `project.yml`

> **Note:** The font file itself (`HyliaSerif.otf`) must be manually downloaded and placed at `app/Sources/Resources/Fonts/HyliaSerif.otf` before building. Search "Hylia Serif font download" — it's a free fan-made font. It is **not committed** to the repo. If the file is absent, `Font.custom` silently falls back to the system font — no crash.

- [ ] **Step 1: Add `UIAppFonts` to `project.yml`**

In `project.yml`, find the `info:` → `properties:` block and add `UIAppFonts`:

```yaml
    info:
      path: app/Info.plist
      properties:
        CFBundleName: TOTKWalkthrough
        CFBundleDisplayName: TOTK Walkthrough
        CFBundleIdentifier: com.totk.walkthrough
        CFBundleVersion: "1"
        CFBundleShortVersionString: "1.0"
        UILaunchScreen: {}
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        UIAppFonts:
          - HyliaSerif.otf
```

- [ ] **Step 2: Add `.gitkeep` so the fonts directory is tracked**

```bash
mkdir -p app/Sources/Resources/Fonts
touch app/Sources/Resources/Fonts/.gitkeep
echo "app/Sources/Resources/Fonts/*.otf" >> .gitignore
```

- [ ] **Step 3: Regenerate the Xcode project**

```bash
xcodegen generate
```

Expected: `⚙️  Generating plists...` then `⚙️  Generating project...` with no errors.

- [ ] **Step 4: Commit**

```bash
git add project.yml app/Sources/Resources/Fonts/.gitkeep .gitignore
git commit -m "feat: register HyliaSerif font in project config"
```

---

## Task 5: Inject ThemeManager at root

**Files:**
- Modify: `app/Sources/Views/TOTKWalkthroughApp.swift`
- Modify: `app/Sources/Views/RootTabView.swift`
- Modify: `app/Tests/SnapshotTests.swift`

- [ ] **Step 1: Update `TOTKWalkthroughApp.swift`**

```swift
// TOTKWalkthroughApp.swift — App entry point. Injects shared stores into the environment.
import SwiftUI

@main
struct TOTKWalkthroughApp: App {
    @StateObject private var contentStore = ContentStore()
    @StateObject private var progressStore = ProgressStore()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(contentStore)
                .environmentObject(progressStore)
                .environmentObject(themeManager)
                .task {
                    try? await contentStore.load()
                }
        }
    }
}
```

- [ ] **Step 2: Update `RootTabView.swift`**

```swift
// RootTabView.swift — Root 4-tab navigation container.
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
            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
        }
        .tint(themeManager.colors.tabActive)
    }
}
```

- [ ] **Step 3: Update `SnapshotTests.swift` to inject ThemeManager**

Replace the entire content of `app/Tests/SnapshotTests.swift` with:

```swift
```swift
// SnapshotTests.swift — SwiftUI snapshot tests for major screens.
import XCTest
import SnapshotTesting
import SwiftUI
@testable import TOTKWalkthrough

final class SnapshotTests: XCTestCase {

    private var contentStore: ContentStore!
    private var progressStore: ProgressStore!
    private var themeManager: ThemeManager!

    override func setUpWithError() throws {
        let fixturesURL = Bundle(for: type(of: self)).bundleURL
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures")
        contentStore = ContentStore(contentURL: fixturesURL)
        progressStore = ProgressStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        themeManager = ThemeManager()
    }

    private func snapshotView<V: View>(_ view: V, named name: String, record: Bool = false) {
        let vc = UIHostingController(rootView:
            view
                .environmentObject(contentStore)
                .environmentObject(progressStore)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
        )
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        assertSnapshot(of: vc, as: .image(on: .iPhone13Pro), named: name, record: record)
    }

    func test_walkthroughTab_snapshot() async throws {
        try await contentStore.load()
        snapshotView(WalkthroughTabView(), named: "WalkthroughTab")
    }

    func test_questsTab_snapshot() async throws {
        try await contentStore.load()
        snapshotView(QuestsTabView(), named: "QuestsTab")
    }

    func test_sideQuestsTab_snapshot() async throws {
        try await contentStore.load()
        snapshotView(SideQuestsTabView(), named: "SideQuestsTab")
    }

    func test_progressTab_snapshot() async throws {
        try await contentStore.load()
        snapshotView(ProgressTabView(), named: "ProgressTab")
    }

    func test_questDetail_snapshot() async throws {
        try await contentStore.load()
        guard let quest = contentStore.quests.first else {
            XCTFail("No quests loaded from fixtures")
            return
        }
        snapshotView(QuestDetailView(quest: quest), named: "QuestDetail")
    }
}
```
```

- [ ] **Step 4: Build and run all tests**

```
xcodebuild test -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthroughTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20
```

Expected: `** TEST SUCCEEDED **` (snapshot tests will fail due to changed views — that's fine, we'll update baselines in Task 13)

- [ ] **Step 5: Commit**

```bash
git add app/Sources/Views/TOTKWalkthroughApp.swift \
        app/Sources/Views/RootTabView.swift \
        app/Tests/SnapshotTests.swift
git commit -m "feat: inject ThemeManager into environment at app root"
```

---

## Task 6: Theme WalkthroughTabView

**Files:**
- Modify: `app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift`

- [ ] **Step 1: Replace the full file**

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
        let done = contentStore.quests.filter { isQuestComplete($0) }.count
        return Double(done) / Double(total)
    }

    private func isQuestComplete(_ quest: Quest) -> Bool {
        guard let blocks = try? contentStore.contentBlocks(for: quest) else { return false }
        let checkpointIDs = blocks.compactMap { block -> String? in
            if case .checkpoint(let id, _) = block { return id }
            return nil
        }
        return !checkpointIDs.isEmpty && checkpointIDs.allSatisfy { progressStore.isCheckpointComplete($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Main Quest Progress")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(themeManager.colors.primaryText)
                            Spacer()
                            Text("\(Int(completionFraction * Double(contentStore.quests.count))) / \(contentStore.quests.count)")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.accent)
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
                        NavigationLink(destination: QuestDetailView(quest: quest)) {
                            HStack(spacing: 12) {
                                Image(systemName: isQuestComplete(quest) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isQuestComplete(quest) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                                Text(quest.title)
                                    .foregroundColor(isQuestComplete(quest) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                    .strikethrough(isQuestComplete(quest))
                            }
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Quest Order")
                        .foregroundColor(themeManager.colors.sectionLabel)
                }
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Walkthrough")
                        .font(themeManager.headingFont(size: 20))
                        .foregroundColor(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(themeManager.colors.accent)
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

- [ ] **Step 2: Build**

```
xcodebuild build -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthrough \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift
git commit -m "feat: apply theme to WalkthroughTabView"
```

---

## Task 7: Theme QuestsTabView

**Files:**
- Modify: `app/Sources/Views/QuestsTab/QuestsTabView.swift`

- [ ] **Step 1: Replace the full file**

```swift
// QuestsTabView.swift — Browsable list of all main quests.
import SwiftUI

struct QuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List(contentStore.quests) { quest in
                NavigationLink(destination: QuestDetailView(quest: quest)) {
                    Text(quest.title)
                        .foregroundColor(themeManager.colors.primaryText)
                }
                .listRowBackground(themeManager.colors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Quests")
                        .font(themeManager.headingFont(size: 20))
                        .foregroundColor(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(themeManager.colors.accent)
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

- [ ] **Step 2: Build**

```
xcodebuild build -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthrough \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/QuestsTab/QuestsTabView.swift
git commit -m "feat: apply theme to QuestsTabView"
```

---

## Task 8: Theme SideQuestsTabView

**Files:**
- Modify: `app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift`

- [ ] **Step 1: Replace the full file**

```swift
// SideQuestsTabView.swift — Browsable list of all side quests.
import SwiftUI

struct SideQuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List(contentStore.sideQuests) { quest in
                NavigationLink(destination: QuestDetailView(quest: quest)) {
                    Text(quest.title)
                        .foregroundColor(themeManager.colors.primaryText)
                }
                .listRowBackground(themeManager.colors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(themeManager.colors.background)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Side Quests")
                        .font(themeManager.headingFont(size: 20))
                        .foregroundColor(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(themeManager.colors.accent)
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

- [ ] **Step 2: Build**

```
xcodebuild build -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthrough \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift
git commit -m "feat: apply theme to SideQuestsTabView"
```

---

## Task 9: Theme ProgressTabView

**Files:**
- Modify: `app/Sources/Views/ProgressTab/ProgressTabView.swift`

- [ ] **Step 1: Replace the full file**

```swift
// ProgressTabView.swift — Completion stats and progress reset.
import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingResetConfirm = false
    @State private var showingSettings = false

    private var completedCount: Int {
        progressStore.completedCheckpoints.count
    }

    private var totalCheckpoints: Int {
        contentStore.quests.compactMap { quest in
            try? contentStore.contentBlocks(for: quest)
        }
        .flatMap { $0 }
        .filter { if case .checkpoint = $0 { return true }; return false }
        .count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Total Quests", value: "\(contentStore.quests.count)")
                        .foregroundColor(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                } header: {
                    Text("Main Quests").foregroundColor(themeManager.colors.sectionLabel)
                }

                Section {
                    LabeledContent("Total Side Quests", value: "\(contentStore.sideQuests.count)")
                        .foregroundColor(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                } header: {
                    Text("Side Quests").foregroundColor(themeManager.colors.sectionLabel)
                }

                Section {
                    LabeledContent("Completed", value: "\(completedCount) / \(totalCheckpoints)")
                        .foregroundColor(themeManager.colors.primaryText)
                        .listRowBackground(themeManager.colors.cardBackground)
                    if totalCheckpoints > 0 {
                        ProgressView(value: Double(completedCount), total: Double(totalCheckpoints))
                            .tint(themeManager.colors.progressFill)
                            .listRowBackground(themeManager.colors.cardBackground)
                    }
                } header: {
                    Text("Checkpoints").foregroundColor(themeManager.colors.sectionLabel)
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
                        .foregroundColor(themeManager.colors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(themeManager.colors.accent)
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
                Text("This will clear all completed checkpoints and your bookmark.")
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 2: Build**

```
xcodebuild build -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthrough \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/ProgressTab/ProgressTabView.swift
git commit -m "feat: apply theme to ProgressTabView"
```

---

## Task 10: Theme QuestDetailView

**Files:**
- Modify: `app/Sources/Views/QuestDetail/QuestDetailView.swift`

- [ ] **Step 1: Replace the full file**

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
                        .foregroundColor(themeManager.colors.secondaryText)
                        .padding()
                } else {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
            }
            .padding()
        }
        .background(themeManager.colors.background)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(quest.title)
                    .font(themeManager.headingFont(size: 18))
                    .foregroundColor(themeManager.colors.accent)
                    .lineLimit(1)
            }
        }
        .toolbarBackground(themeManager.colors.navBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { loadBlocks() }
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block {
        case .text(let markdown):
            if let attributed = try? AttributedString(markdown: markdown) {
                Text(attributed)
                    .font(.body)
                    .foregroundColor(themeManager.colors.primaryText)
            } else {
                Text(markdown)
                    .font(.body)
                    .foregroundColor(themeManager.colors.primaryText)
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

- [ ] **Step 2: Build**

```
xcodebuild build -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthrough \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/QuestDetail/QuestDetailView.swift
git commit -m "feat: apply theme to QuestDetailView"
```

---

## Task 11: Theme CheckpointCard

**Files:**
- Modify: `app/Sources/Views/QuestDetail/CheckpointCard.swift`

- [ ] **Step 1: Replace the full file**

```swift
// CheckpointCard.swift — Inline card for a quest checkpoint with a "Mark Done" button.
import SwiftUI

struct CheckpointCard: View {
    let id: String
    let label: String
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(
                        progressStore.isCheckpointComplete(id)
                            ? themeManager.colors.checkpointDone
                            : themeManager.colors.checkpointPending,
                        lineWidth: 2
                    )
                    .frame(width: 22, height: 22)
                if progressStore.isCheckpointComplete(id) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeManager.colors.checkpointDone)
                } else {
                    Circle()
                        .fill(themeManager.colors.checkpointPending)
                        .frame(width: 9, height: 9)
                }
            }

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(themeManager.colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !progressStore.isCheckpointComplete(id) {
                Button("Mark Done") {
                    progressStore.markCheckpoint(id)
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(themeManager.colors.accent)
                .foregroundColor(themeManager.colors.accentText)
                .clipShape(Capsule())
            }
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

- [ ] **Step 2: Build**

```
xcodebuild build -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthrough \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/QuestDetail/CheckpointCard.swift
git commit -m "feat: apply theme to CheckpointCard"
```

---

## Task 12: Theme BookmarkCard

**Files:**
- Modify: `app/Sources/Views/WalkthroughTab/BookmarkCard.swift`

- [ ] **Step 1: Replace the full file**

```swift
// BookmarkCard.swift — "Currently On" card showing the active quest bookmark.
import SwiftUI

struct BookmarkCard: View {
    let quests: [Quest]
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager

    private var currentQuest: Quest? {
        guard let slug = progressStore.bookmark?.questSlug else { return nil }
        return quests.first { $0.slug == slug }
    }

    var body: some View {
        if let quest = currentQuest {
            VStack(alignment: .leading, spacing: 4) {
                Text("Currently On")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(themeManager.colors.accent)
                    .textCase(.uppercase)
                Text(quest.title)
                    .font(.headline)
                    .foregroundColor(themeManager.colors.primaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
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
}
```

- [ ] **Step 2: Build**

```
xcodebuild build -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthrough \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add app/Sources/Views/WalkthroughTab/BookmarkCard.swift
git commit -m "feat: apply theme to BookmarkCard"
```

---

## Task 13: Update snapshot baselines

**Files:**
- Modify: `app/Tests/SnapshotTests.swift` (record mode on → off)

The snapshot images are now stale because every view changed. Re-record them.

- [ ] **Step 1: Enable record mode in `SnapshotTests.swift`**

Change the `snapshotView` helper call signature — set `record: true` as default temporarily:

```swift
    private func snapshotView<V: View>(_ view: V, named name: String, record: Bool = true) {
```

- [ ] **Step 2: Run snapshot tests in record mode**

```
xcodebuild test -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthroughTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TOTKWalkthroughTests/SnapshotTests 2>&1 | tail -10
```

Expected: Tests "fail" with `"Record mode is on"` — this is correct, new images are written to `app/Tests/__Snapshots__/`.

- [ ] **Step 3: Disable record mode**

Change the default back:

```swift
    private func snapshotView<V: View>(_ view: V, named name: String, record: Bool = false) {
```

- [ ] **Step 4: Run snapshot tests — confirm they pass**

```
xcodebuild test -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthroughTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:TOTKWalkthroughTests/SnapshotTests 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 5: Run all tests**

```
xcodebuild test -project TOTKWalkthrough.xcodeproj \
  -scheme TOTKWalkthroughTests \
  -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add app/Tests/SnapshotTests.swift app/Tests/__Snapshots__/
git commit -m "test: update snapshot baselines for Zelda theming"
```
