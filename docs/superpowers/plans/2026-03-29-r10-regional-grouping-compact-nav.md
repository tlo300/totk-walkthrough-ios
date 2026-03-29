# R10: Regional Grouping, Completion Parity & Compact Nav — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-region grouping to Adventures/Side Quests/Shrines, complete Adventures tab parity, slim the nav bar on all list tabs, then ship as R10.

**Architecture:** Add optional `region: String?` to the Quest model + JSON indexes; group list items using `Dictionary(grouping:)` + a shared `regionOrder` constant; replace toolbar-based nav bar with a thin custom `TabHeaderView`.

**Tech Stack:** Swift 5.9, SwiftUI, JSON

---

## File Map

| Action | Path |
|--------|------|
| Modify | `app/Sources/Models/Quest.swift` |
| Modify | `app/Sources/ModelConfig.swift` |
| Create | `app/Sources/Views/TabHeaderView.swift` |
| Modify | `app/Sources/Views/AdventuresTab/AdventuresTabView.swift` |
| Modify | `app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift` |
| Modify | `app/Sources/Views/Shrines/ShrinesTabView.swift` |
| Modify | `app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift` |
| Modify | `app/Sources/Views/ProgressTab/ProgressTabView.swift` |
| Modify | `app/Resources/Content/shrines/index.json` |
| Modify | `app/Resources/Content/adventures/index.json` |
| Modify | `app/Resources/Content/side-quests/index.json` |
| Modify | `app/Tests/Fixtures/shrines/index.json` |

---

## Task 1: Add `region` to Quest model + `regionOrder` to ModelConfig

**Files:**
- Modify: `app/Sources/Models/Quest.swift`
- Modify: `app/Sources/ModelConfig.swift`

- [ ] **Step 1.1: Update Quest model**

Replace the full contents of `app/Sources/Models/Quest.swift`:

```swift
// Quest.swift — Quest and SideQuest data model loaded from quest-order.json.
import Foundation

enum QuestType: String, Codable {
    case main
    case side = "side-quest"
    case shrine
    case adventure
}

struct Quest: Identifiable, Codable, Hashable {
    let slug: String
    let title: String
    let type: QuestType
    let region: String?

    var id: String { slug }
}

struct QuestOrder: Codable {
    let quests: [Quest]
}
```

- [ ] **Step 1.2: Add regionOrder to ModelConfig**

Add to `app/Sources/ModelConfig.swift` inside the `ModelConfig` enum (after the last `static let`):

```swift
    static let regionOrder = [
        "Great Sky Island", "Central Hyrule", "Eldin", "Akkala",
        "Hebra", "Lanayru", "Necluda", "Faron", "Gerudo"
    ]
```

- [ ] **Step 1.3: Update test fixture to include region**

Replace `app/Tests/Fixtures/shrines/index.json`:

```json
{
  "quests": [
    { "slug": "test-shrine", "title": "Test Shrine", "type": "shrine", "region": "Central Hyrule" }
  ],
  "sideQuests": []
}
```

- [ ] **Step 1.4: Run existing tests to confirm decode still works**

```
cd "c:/Users/twanv/Zeldo TOTK Walkthrough Framework"
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20
```

Expected: no decode failures; existing tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add app/Sources/Models/Quest.swift app/Sources/ModelConfig.swift app/Tests/Fixtures/shrines/index.json
git commit -m "feat: add region field to Quest model and regionOrder constant"
```

---

## Task 2: Add region data to shrines/index.json

**Files:**
- Modify: `app/Resources/Content/shrines/index.json`

Region assignments (slug → region):

| id | slug | region |
|----|------|--------|
| 1 | ukouh-shrine | Great Sky Island |
| 2 | in-isa-shrine | Great Sky Island |
| 3 | gutanbac-shrine | Great Sky Island |
| 4 | nachoyah-shrine | Great Sky Island |
| 5 | yamiyo-shrine | Central Hyrule |
| 6 | kyononis-shrine | Central Hyrule |
| 7 | ishodag-shrine | Central Hyrule |
| 8 | sinakawak-shrine | Central Hyrule |
| 9 | jiosin-shrine | Central Hyrule |
| 10 | susuyai-shrine | Central Hyrule |
| 11 | mayachin-shrine | Central Hyrule |
| 12 | teniten-shrine | Central Hyrule |
| 13 | tajikats-shrine | Lanayru |
| 14 | kamizun-shrine | Central Hyrule |
| 15 | kyokugon-shrine | Central Hyrule |
| 16 | kyokugon-shrine | Central Hyrule |
| 17 | tsutsu-um-shrine | Central Hyrule |
| 18 | riogok-shrine | Eldin |
| 19 | tadarok-shrine | Eldin |
| 20 | serutabomac-shrine | Central Hyrule |
| 21 | sepapa-shrine | Central Hyrule |
| 22 | ren-iz-shrine | Central Hyrule |
| 23 | jojon-shrine | Akkala |
| 24 | jojon-shrine | Akkala |
| 25 | jinodok-shrine | Eldin |
| 26 | taunhiy-shrine | Hebra |
| 27 | simosiwak-shrine | Hebra |
| 28 | mayam-shrine | Hebra |
| 29 | orochium-shrine | Hebra |
| 30 | nouda-shrine | Hebra |
| 31 | oromuwak-shrine | Hebra |
| 32 | gatakis-shrine | Hebra |
| 33 | wao-os-shrine | Hebra |
| 34 | sahirow-shrine | Hebra |
| 35 | tauyosipun-shrine | Hebra |
| 36 | otak-shrine | Central Hyrule |
| 37 | eutoum-shrine | Central Hyrule |
| 38 | rutafu-um-shrine | Akkala |
| 39 | sisuran-shrine | Akkala |
| 40 | oshozan-u-shrine | Akkala |
| 41 | mayaotaki-shrine | Akkala |
| 42 | ganos-shrine | Akkala |
| 43 | ga-ahisas-shrine | Akkala |
| 44 | ijo-o-shrine | Hebra |
| 45 | ijo-o-shrine | Hebra |
| 46 | kahatanaum-shrine | Akkala |
| 47 | mayaumekis-shrine | Hebra |
| 48 | taninoud-shrine | Hebra |
| 49 | tenbez-shrine | Hebra |
| 50 | mayausiy-shrine | Hebra |
| 51 | ikatak-shrine | Akkala |
| 52 | turakawak-shrine | Akkala |
| 53 | iun-orok-shrine | Lanayru |
| 54 | iun-orok-shrine | Lanayru |
| 55 | gasas-shrine | Gerudo |
| 56 | kiuyoyou-shrine | Gerudo |
| 57 | usazum-shrine | Gerudo |
| 58 | sonapan-shrine | Akkala |
| 59 | makurukis-shrine | Eldin |
| 60 | runakit-shrine | Eldin |
| 61 | taki-ihaban-shrine | Lanayru |
| 62 | tenmaten-shrine | Lanayru |
| 63 | gemimik-shrine | Akkala |
| 64 | jochi-iu-shrine | Lanayru |
| 65 | mayachideg-shrine | Lanayru |
| 66 | kamatukis-shrine | Eldin |
| 67 | sinatanika-shrine | Eldin |
| 68 | rasitakiwak-shrine | Lanayru |
| 69 | jochi-ihiga-shrine | Lanayru |
| 70 | gatanisis-shrine | Eldin |
| 71 | rasiwak-shrine | Eldin |
| 72 | igashuk-shrine | Hebra |
| 73 | domizuin-shrine | Eldin |
| 74 | kimayat-shrine | Eldin |
| 75 | momosik-shrine | Lanayru |
| 76 | natak-shrine | Eldin |
| 77 | gikaku-shrine | Lanayru |
| 78 | mogisari-shrine | Lanayru |
| 79 | timawak-shrine | Faron |
| 80 | marakuguc-shrine | Faron |
| 81 | isisim-shrine | Faron |
| 82 | sitsum-shrine | Central Hyrule |
| 83 | kikakin-shrine | Necluda |
| 84 | minetak-shrine | Necluda |
| 85 | sikukuu-shrine | Lanayru |
| 86 | mayak-shrine | Necluda |
| 87 | jiotak-shrine | Necluda |
| 88 | sibajitak-shrine | Akkala |
| 89 | moshapin-shrine | Necluda |
| 90 | kisinona-shrine | Faron |
| 91 | kadaunar-shrine | Gerudo |
| 92 | utsushok-shrine | Lanayru |
| 93 | joju-u-u-shrine | Faron |
| 94 | utojis-shrine | Gerudo |
| 95 | jiukoum-shrine | Gerudo |
| 96 | ishokin-shrine | Gerudo |
| 97 | joku-usin-shrine | Faron |
| 98 | joku-u-shrine | Faron |
| 99 | miryotanog-shrine | Gerudo |
| 100 | kudanisar-shrine | Gerudo |
| 101 | soryotanog-shrine | Faron |
| 102 | mayatat-shrine | Gerudo |
| 103 | siwakama-shrine | Gerudo |
| 104 | chichim-shrine | Gerudo |
| 105 | irasak-shrine | Gerudo |
| 106 | karahatag-shrine | Gerudo |
| 107 | suariwak-shrine | Gerudo |
| 108 | otutsum-shrine | Faron |
| 109 | mayamats-shrine | Faron |
| 110 | rotsumamu-shrine | Faron |
| 111 | motsusis-shrine | Faron |
| 112 | kitawak-shrine | Necluda |
| 113 | rakakudaj-shrine | Necluda |
| 114 | turakamik-shrine | Necluda |
| 115 | rakashog-shrine | Necluda |
| 116 | mayasiar-shrine | Necluda |
| 117 | siyamotsus-shrine | Necluda |
| 118 | morok-shrine | Necluda |
| 119 | tukarok-shrine | Eldin |
| 120 | jikais-shrine | Necluda |
| 121 | jogou-shrine | Eldin |
| 122 | zakusu-shrine | Eldin |
| 123 | mogawak-shrine | Eldin |
| 124 | jonsau-shrine | Lanayru |
| 125 | kurakat-shrine | Necluda |
| 126 | joniu-shrine | Lanayru |
| 127 | ihen-a-shrine | Lanayru |
| 128 | apogek-shrine | Faron |
| 129 | yomizuk-shrine | Lanayru |
| 130 | maoikes-shrine | Necluda |
| 131 | sihajog-shrine | Necluda |
| 132 | jirutagumac-shrine | Necluda |
| 133 | igoshon-shrine | Necluda |
| 134 | mayanas-shrine | Necluda |
| 135 | en-oma-shrine | Lanayru |
| 136 | susub-shrine | Faron |
| 137 | jochisiu-shrine | Lanayru |
| 138 | o-ogim-shrine | Lanayru |
| 139 | zanmik-shrine | Akkala |
| 140 | mayahisik-shrine | Lanayru |
| 141 | sifumim-shrine | Gerudo |
| 142 | makasura-shrine | Necluda |
| 143 | eshos-shrine | Necluda |
| 144 | marari-in-shrine | Necluda |
| 145 | tokiy-shrine | Necluda |
| 146 | anedamimik-shrine | Necluda |
| 147 | bamitok-shrine | Necluda |
| 148 | josiu-shrine | Necluda |
| 149 | ukoojisi-shrine | Akkala |
| 150 | kumamayn-shrine | Necluda |
| 151 | yansamin-shrine | Gerudo |
| 152 | musanokir-shrine | Gerudo |
| 153 | ekochiu-shrine | Eldin |
| 154 | pupunke-shrine | Akkala |
| 155 | ninjis-shrine | Necluda |
| 156 | sakunbomar-shrine | Eldin |

- [ ] **Step 2.1: Apply region assignments**

Each quest entry in `app/Resources/Content/shrines/index.json` must gain `"region": "<value>"` per the table above. The entry format changes from:
```json
{ "id": 5, "slug": "yamiyo-shrine", "title": "Yamiyo Shrine", "type": "shrine" }
```
to:
```json
{ "id": 5, "slug": "yamiyo-shrine", "title": "Yamiyo Shrine", "type": "shrine", "region": "Central Hyrule" }
```

Apply to all 156 entries using the table above.

- [ ] **Step 2.2: Commit**

```bash
git add app/Resources/Content/shrines/index.json
git commit -m "feat: add region field to all 156 shrine entries"
```

---

## Task 3: Add region data to adventures/index.json

**Files:**
- Modify: `app/Resources/Content/adventures/index.json`

| id | slug | region |
|----|------|--------|
| 1 | hateno-village-research-lab | Necluda |
| 2 | messages-from-an-ancient-era | Necluda |
| 3 | who-goes-there | Hebra |
| 4 | a-deal-with-the-statue | Central Hyrule |
| 5 | bring-peace-to-hyrule-field! | Central Hyrule |
| 6 | the-beckoning-woman | Necluda |
| 7 | serenade-to-kaysa | Hebra |
| 8 | gourmets-gone-missing | Central Hyrule |
| 9 | a-call-from-the-depths | Central Hyrule |
| 10 | the-beast-and-the-princess | Central Hyrule |
| 11 | hestu's-concerns | Central Hyrule |
| 12 | where-to-find-hestu---inventory-expansion | Central Hyrule |
| 13 | white-goats-gone-missing | Necluda |
| 14 | potential-princess-sightings! | Hebra |
| 15 | froggy-armor-set | Faron |
| 16 | zelda's-golden-horse | Necluda |
| 17 | golden-horse | Necluda |
| 18 | serenade-to-mija | Akkala |
| 19 | the-hornist's-dramatic-escape | Hebra |
| 20 | bring-peace-to-hebra! | Hebra |
| 21 | for-our-princess! | Gerudo |
| 22 | serenade-to-a-great-fairy | Hebra |
| 23 | the-hunt-for-bubbul-gems! | Central Hyrule |
| 24 | bokoblin-mask | Central Hyrule |
| 25 | bring-peace-to-eldin! | Eldin |
| 26 | mattison's-independence | Gerudo |
| 27 | the-search-for-koltin | Central Hyrule |
| 28 | bubbul-gems---rewards-and-tips | Central Hyrule |
| 29 | a-monstrous-collection-i | Akkala |
| 30 | a-monstrous-collection-ii | Akkala |
| 31 | a-monstrous-collection-iii | Akkala |
| 32 | a-monstrous-collection-iv | Akkala |
| 33 | a-monstrous-collection-v | Akkala |
| 34 | the-all-clucking-cucco | Central Hyrule |
| 35 | bring-peace-to-akkala! | Akkala |
| 36 | filling-out-the-compendium | Akkala |
| 37 | presenting-the-travel-medallion | Akkala |
| 38 | presenting-hero's-path-mode | Akkala |
| 39 | presenting-sensor-+! | Akkala |
| 40 | a-letter-to-koyin | Necluda |
| 41 | a-new-signature-food | Necluda |
| 42 | reede's-secret | Necluda |
| 43 | cece's-secret | Necluda |
| 44 | team-cece-or-team-reede | Necluda |
| 45 | the-mayoral-election | Necluda |
| 46 | cece-hat | Necluda |
| 47 | ruffian-infested-village | Faron |
| 48 | lurelin-village-restoration-project | Faron |
| 49 | the-missing-farm-tools | Necluda |
| 50 | princess-zelda-kidnapped! | Central Hyrule |
| 51 | serenade-to-cotera | Necluda |
| 52 | bring-peace-to-necluda! | Necluda |
| 53 | honey,-bee-mine | Faron |
| 54 | an-eerie-voice | Necluda |
| 55 | the-flute-player's-plan | Akkala |
| 56 | bring-peace-to-faron! | Faron |
| 57 | the-blocked-well | Necluda |
| 58 | infiltrating-the-yiga-clan | Gerudo |
| 59 | the-yiga-clan-exam | Gerudo |
| 60 | investigate-the-thyphlo-ruins | Central Hyrule |
| 61 | the-owl-protected-by-dragons | Central Hyrule |
| 62 | the-corridor-between-two-dragons | Central Hyrule |
| 63 | the-six-dragons | Central Hyrule |
| 64 | the-long-dragon | Central Hyrule |
| 65 | legend-of-the-great-sky-island | Great Sky Island |
| 66 | master-kohga-of-the-yiga-clan | Gerudo |
| 67 | all-schema-stone-locations | Central Hyrule |

- [ ] **Step 3.1: Apply region assignments**

Each entry gains `"region": "<value>"` per table. Same format change as Task 2.

- [ ] **Step 3.2: Commit**

```bash
git add app/Resources/Content/adventures/index.json
git commit -m "feat: add region field to all adventure entries"
```

---

## Task 4: Add region data to side-quests/index.json

**Files:**
- Modify: `app/Resources/Content/side-quests/index.json`

| id | slug | region |
|----|------|--------|
| 1 | spotting-spot | Central Hyrule |
| 2 | village-attacked-by-pirates | Faron |
| 3 | today's-menu | Eldin |
| 4 | the-incomplete-stable | Eldin |
| 5 | wanted-stone-talus | Central Hyrule |
| 6 | wanted-molduga | Gerudo |
| 7 | wanted-hinox | Central Hyrule |
| 8 | unknown-sky-giant | Central Hyrule |
| 9 | unknown-three-headed-monster | Central Hyrule |
| 10 | unknown-huge-silhouette | Central Hyrule |
| 11 | fell-into-a-well! | Central Hyrule |
| 12 | the-horse-guard's-request | Central Hyrule |
| 13 | a-picture-for-outskirt-stable | Central Hyrule |
| 14 | pony-points-card | Central Hyrule |
| 15 | feathered-fugitives | Central Hyrule |
| 16 | a-picture-for-riverside-stable | Central Hyrule |
| 17 | misko's-treasure-of-awakening-iii | Central Hyrule |
| 18 | mask-of-awakening | Central Hyrule |
| 19 | horse-drawn-dreams | Central Hyrule |
| 20 | a-picture-for-new-serenne-stable | Hebra |
| 21 | a-picture-for-tabantha-bridge-stable | Hebra |
| 22 | the-mother-goddess-statue | Necluda |
| 23 | white-sword-of-the-sky | Hebra |
| 24 | genli's-home-cooking | Hebra |
| 25 | treasure-of-the-secret-springs | Hebra |
| 26 | vah-medoh-divine-helm | Hebra |
| 27 | molli-the-fletcher's-quest | Hebra |
| 28 | legacy-of-the-rito | Hebra |
| 29 | great-eagle-bow | Hebra |
| 30 | fish-for-fletching | Hebra |
| 31 | the-rito-rope-bridge | Hebra |
| 32 | cave-mushrooms-that-glow | Hebra |
| 33 | misko's-treasure-of-awakening-ii | Hebra |
| 34 | trousers-of-awakening | Hebra |
| 35 | a-picture-for-snowfield-stable | Hebra |
| 36 | the-captured-tent | Hebra |
| 37 | who-finds-the-haven | Hebra |
| 38 | crossing-the-cold-pool | Hebra |
| 39 | open-the-door | Hebra |
| 40 | supply-eyeing-fliers | Hebra |
| 41 | the-blocked-cave | Hebra |
| 42 | the-duchess-who-disappeared | Hebra |
| 43 | kaneli's-flight-training | Hebra |
| 44 | hebra's-colossal-fossil | Hebra |
| 45 | the-north-lomei-prophecy | Hebra |
| 46 | evil-spirit-armor-set | Hebra |
| 47 | secrets-within | Hebra |
| 48 | master-the-vehicle-prototype | Hebra |
| 49 | home-on-arrange | Akkala |
| 50 | the-tarrey-town-race-is-on! | Akkala |
| 51 | strongest-in-the-world | Akkala |
| 52 | the-gathering-pirates | Akkala |
| 53 | a-picture-for-east-akkala-stable | Akkala |
| 54 | eldin's-colossal-fossil | Eldin |
| 55 | one-hit-wonder! | Akkala |
| 56 | a-picture-for-south-akkala-stable | Akkala |
| 57 | goddess-statue-of-power | Akkala |
| 58 | lomei-labyrinth-island | Akkala |
| 59 | where-are-the-wells | Central Hyrule |
| 60 | amber-dealer | Eldin |
| 61 | the-ancient-city-gorondia! | Eldin |
| 62 | the-ancient-city-gorondia | Eldin |
| 63 | soul-of-the-gorons | Eldin |
| 64 | boulder-breaker | Eldin |
| 65 | moon-gazing-gorons | Eldin |
| 66 | the-hidden-treasure-at-lizard-lakes | Eldin |
| 67 | vah-rudania-divine-helmet | Eldin |
| 68 | simmerstone-springs | Eldin |
| 69 | cash-in-on-ripened-flint | Eldin |
| 70 | meat-for-meat | Eldin |
| 71 | rock-roast-or-dust | Eldin |
| 72 | mine-cart-land-open-for-business! | Eldin |
| 73 | mine-cart-land-quickshot-course | Eldin |
| 74 | mine-cart-land-death-mountain | Eldin |
| 75 | a-picture-for-foothill-stable | Eldin |
| 76 | the-abandoned-laborer | Eldin |
| 77 | misko's-cave-of-chests | Akkala |
| 78 | ember-trousers | Eldin |
| 79 | misko's-treasure-the-fierce-deity | Akkala |
| 80 | fierce-deity-sword | Akkala |
| 81 | misko's-treasure-twins-manuscript | Central Hyrule |
| 82 | tingle's-shirt | Central Hyrule |
| 83 | misko's-treasure-pirate-manuscript | Faron |
| 84 | tingle's-tights | Faron |
| 85 | misko's-treasure-heroines-manuscript | Gerudo |
| 86 | tingle's-hood | Gerudo |
| 87 | misko's-treasure-of-awakening-i | Central Hyrule |
| 88 | tunic-of-awakening | Central Hyrule |
| 89 | a-picture-for-wetland-stable | Lanayru |
| 90 | an-uninvited-guest | Lanayru |
| 91 | a-picture-for-dueling-peaks-stable | Necluda |
| 92 | out-of-the-inn | Necluda |
| 93 | follow-the-cuccos | Necluda |
| 94 | a-trip-through-history | Necluda |
| 95 | thunderwing-butterfly | Necluda |
| 96 | codgers'-quarrel | Necluda |
| 97 | gloom-borne-illness | Necluda |
| 98 | a-new-champion's-tunic | Necluda |
| 99 | champion's-leathers | Necluda |
| 100 | teach-me-a-lesson-i | Necluda |
| 101 | teach-me-a-lesson-ii | Necluda |
| 102 | dantz's-prize-cows | Necluda |
| 103 | homegrown-in-hateno | Necluda |
| 104 | photographing-a-chuchu | Necluda |
| 105 | uma's-garden | Necluda |
| 106 | manny's-beloved | Necluda |
| 107 | lurelin-resort-project | Faron |
| 108 | dad's-blue-shirt | Faron |
| 109 | island-lobster-shirt | Faron |
| 110 | a-way-to-trade,-washed-away | Faron |
| 111 | rattled-ralera | Faron |
| 112 | a-bottled-cry-for-help | Faron |
| 113 | seeking-the-pirate-hideout | Faron |
| 114 | ousting-the-giants | Faron |
| 115 | a-picture-for-lakeside-stable | Faron |
| 116 | a-picture-for-highland-stable | Faron |
| 117 | goddess-statue-of-courage | Necluda |
| 118 | gerudo's-colossal-fossil | Gerudo |
| 119 | the-heroines'-secret | Gerudo |
| 120 | treasure-of-the-gerudo-desert | Gerudo |
| 121 | vah-naboris-divine-helm | Gerudo |
| 122 | pride-of-the-gerudo | Gerudo |
| 123 | scimitar-of-the-seven | Gerudo |
| 124 | daybreaker | Gerudo |
| 125 | dalia's-game | Gerudo |
| 126 | the-mysterious-eighth | Gerudo |
| 127 | the-missing-owner | Gerudo |
| 128 | to-the-ruins! | Gerudo |
| 129 | decorate-with-passion | Gerudo |
| 130 | lost-in-the-dunes | Gerudo |
| 131 | a-picture-for-closed-stable-i | Gerudo |
| 132 | a-picture-for-closed-stable-ii | Gerudo |
| 133 | piaffe,-packed-away | Gerudo |
| 134 | gleeok-guts | Gerudo |
| 135 | disaster-in-gerudo-canyon | Gerudo |
| 136 | the-great-tumbleweed-purge | Gerudo |
| 137 | heat-endurance-contest! | Eldin |
| 138 | cold-endurance-contest! | Hebra |
| 139 | the-icelesss-icehouse | Gerudo |
| 140 | the-south-lomei-prophecy | Gerudo |
| 141 | whirly-swirly-things | Gerudo |
| 142 | endura-carrot | Central Hyrule |
| 143 | the-secret-room | Gerudo |
| 144 | walton's-treasure-hunt | Central Hyrule |
| 145 | a-picture-for-woodland-stable | Central Hyrule |
| 146 | the-treasure-hunters | Central Hyrule |
| 147 | true-treasure | Central Hyrule |
| 148 | secret-treasure-under-the-great-fish | Lanayru |
| 149 | vah-ruta-divine-helm | Lanayru |
| 150 | the-never-ending-lecture | Lanayru |
| 151 | the-moonlit-princess | Lanayru |
| 152 | zora-sword | Lanayru |
| 153 | the-fort-at-ja'abu-ridge | Lanayru |
| 154 | glory-of-the-zora | Lanayru |
| 155 | lightscale-trident | Lanayru |
| 156 | a-crabulous-deal | Lanayru |
| 157 | a-wife-wafted-away | Lanayru |
| 158 | a-token-of-friendship | Lanayru |
| 159 | the-blue-stone | Lanayru |
| 160 | the-ultimate-dish | Lanayru |
| 161 | mired-in-muck | Lanayru |
| 162 | zora-spear | Lanayru |
| 163 | goddess-statue-of-wisdom | Lanayru |
| 164 | ancient-blades-below | Lanayru |
| 165 | the-shrine-explorer | Central Hyrule |
| 166 | ancient-hero's-aspect | Central Hyrule |

- [ ] **Step 4.1: Apply region assignments** (same pattern: add `"region": "<value>"` field to each entry)

- [ ] **Step 4.2: Commit**

```bash
git add app/Resources/Content/side-quests/index.json
git commit -m "feat: add region field to all side-quest entries"
```

---

## Task 5: Create TabHeaderView

**Files:**
- Create: `app/Sources/Views/TabHeaderView.swift`

- [ ] **Step 5.1: Create the file**

```swift
// TabHeaderView.swift — Compact custom header replacing the system navigation bar on list tabs.
import SwiftUI

struct TabHeaderView: View {
    let title: String
    @Binding var showingSettings: Bool
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            Text(title)
                .font(themeManager.headingFont(size: 20))
                .foregroundStyle(themeManager.colors.accent)
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(themeManager.colors.accent)
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 8)
        .background(themeManager.colors.navBackground)
    }
}
```

- [ ] **Step 5.2: Commit**

```bash
git add app/Sources/Views/TabHeaderView.swift
git commit -m "feat: add compact TabHeaderView to replace system nav bar"
```

---

## Task 6: Rewrite AdventuresTabView

**Files:**
- Modify: `app/Sources/Views/AdventuresTab/AdventuresTabView.swift`

- [ ] **Step 6.1: Replace file contents**

```swift
// AdventuresTabView.swift — Browsable list of all side adventures with completion tracking and regional sections.
import SwiftUI

struct AdventuresTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    private var completionFraction: Double {
        let total = contentStore.adventures.count
        guard total > 0 else { return 0 }
        let done = contentStore.adventures.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    private var grouped: [String: [Quest]] {
        Dictionary(grouping: contentStore.adventures) { $0.region ?? "Other" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Adventures", showingSettings: $showingSettings)
                    .environmentObject(themeManager)

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Adventure Progress")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(themeManager.colors.primaryText)
                                Spacer()
                                Text("\(Int(completionFraction * Double(contentStore.adventures.count))) / \(contentStore.adventures.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(themeManager.colors.accent)
                            }
                            ProgressView(value: completionFraction)
                                .tint(themeManager.colors.progressFill)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(themeManager.colors.cardBackground)
                    }

                    ForEach(ModelConfig.regionOrder.filter { grouped[$0] != nil }, id: \.self) { region in
                        Section {
                            ForEach(grouped[region]!) { quest in
                                HStack(spacing: 12) {
                                    Button {
                                        progressStore.toggleQuest(quest.slug)
                                    } label: {
                                        Image(systemName: progressStore.isQuestComplete(quest.slug) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                                    }
                                    .buttonStyle(.plain)

                                    NavigationLink(destination: QuestDetailView(quest: quest)) {
                                        Text(quest.title)
                                            .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                            .strikethrough(progressStore.isQuestComplete(quest.slug))
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        progressStore.toggleQuest(quest.slug)
                                    } label: {
                                        Label(
                                            progressStore.isQuestComplete(quest.slug) ? "Undo" : "Done",
                                            systemImage: progressStore.isQuestComplete(quest.slug) ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(progressStore.isQuestComplete(quest.slug) ? .gray : .green)
                                }
                                .listRowBackground(themeManager.colors.cardBackground)
                            }
                        } header: {
                            Text(region)
                                .foregroundStyle(themeManager.colors.sectionLabel)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                .toolbar(.hidden, for: .navigationBar)
            }
            .background(themeManager.colors.background)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 6.2: Commit**

```bash
git add app/Sources/Views/AdventuresTab/AdventuresTabView.swift
git commit -m "feat: Adventures tab — completion dots, progress bar, regional sections, compact header"
```

---

## Task 7: Update SideQuestsTabView

**Files:**
- Modify: `app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift`

- [ ] **Step 7.1: Replace file contents**

```swift
// SideQuestsTabView.swift — Browsable list of all side quests with completion tracking and regional sections.
import SwiftUI

struct SideQuestsTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingSettings = false

    private var completionFraction: Double {
        let total = contentStore.sideQuests.count
        guard total > 0 else { return 0 }
        let done = contentStore.sideQuests.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    private var grouped: [String: [Quest]] {
        Dictionary(grouping: contentStore.sideQuests) { $0.region ?? "Other" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Side Quests", showingSettings: $showingSettings)
                    .environmentObject(themeManager)

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Side Quest Progress")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(themeManager.colors.primaryText)
                                Spacer()
                                Text("\(Int(completionFraction * Double(contentStore.sideQuests.count))) / \(contentStore.sideQuests.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(themeManager.colors.accent)
                            }
                            ProgressView(value: completionFraction)
                                .tint(themeManager.colors.progressFill)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(themeManager.colors.cardBackground)
                    }

                    ForEach(ModelConfig.regionOrder.filter { grouped[$0] != nil }, id: \.self) { region in
                        Section {
                            ForEach(grouped[region]!) { quest in
                                HStack(spacing: 12) {
                                    Button {
                                        progressStore.toggleQuest(quest.slug)
                                    } label: {
                                        Image(systemName: progressStore.isQuestComplete(quest.slug) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                                    }
                                    .buttonStyle(.plain)

                                    NavigationLink(destination: QuestDetailView(quest: quest)) {
                                        Text(quest.title)
                                            .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                            .strikethrough(progressStore.isQuestComplete(quest.slug))
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        progressStore.toggleQuest(quest.slug)
                                    } label: {
                                        Label(
                                            progressStore.isQuestComplete(quest.slug) ? "Undo" : "Done",
                                            systemImage: progressStore.isQuestComplete(quest.slug) ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(progressStore.isQuestComplete(quest.slug) ? .gray : .green)
                                }
                                .listRowBackground(themeManager.colors.cardBackground)
                            }
                        } header: {
                            Text(region)
                                .foregroundStyle(themeManager.colors.sectionLabel)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                .toolbar(.hidden, for: .navigationBar)
            }
            .background(themeManager.colors.background)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 7.2: Commit**

```bash
git add app/Sources/Views/SideQuestsTab/SideQuestsTabView.swift
git commit -m "feat: Side Quests tab — progress bar, regional sections, compact header"
```

---

## Task 8: Update ShrinesTabView

**Files:**
- Modify: `app/Sources/Views/Shrines/ShrinesTabView.swift`

- [ ] **Step 8.1: Replace file contents**

```swift
// ShrinesTabView.swift — Shrine list with completion tracking, regional sections, and detail navigation.
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

    private var grouped: [String: [Quest]] {
        Dictionary(grouping: contentStore.shrines) { $0.region ?? "Other" }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Shrines", showingSettings: $showingSettings)
                    .environmentObject(themeManager)

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

                    ForEach(ModelConfig.regionOrder.filter { grouped[$0] != nil }, id: \.self) { region in
                        Section {
                            ForEach(grouped[region]!) { shrine in
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
                            Text(region)
                                .foregroundStyle(themeManager.colors.sectionLabel)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                .toolbar(.hidden, for: .navigationBar)
            }
            .background(themeManager.colors.background)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 8.2: Commit**

```bash
git add app/Sources/Views/Shrines/ShrinesTabView.swift
git commit -m "feat: Shrines tab — per-region sections, compact header"
```

---

## Task 9: Update WalkthroughTabView (compact header only)

**Files:**
- Modify: `app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift`

- [ ] **Step 9.1: Replace file contents**

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
        let done = contentStore.quests.filter { progressStore.isQuestComplete($0.slug) }.count
        return Double(done) / Double(total)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Walkthrough", showingSettings: $showingSettings)
                    .environmentObject(themeManager)

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Main Quest Progress")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(themeManager.colors.primaryText)
                                Spacer()
                                Text("\(Int(completionFraction * Double(contentStore.quests.count))) / \(contentStore.quests.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(themeManager.colors.accent)
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
                            HStack(spacing: 12) {
                                Button {
                                    progressStore.toggleQuest(quest.slug)
                                } label: {
                                    Image(systemName: progressStore.isQuestComplete(quest.slug) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.checkpointDone : themeManager.colors.secondaryText)
                                }
                                .buttonStyle(.plain)

                                NavigationLink(destination: QuestDetailView(quest: quest)) {
                                    Text(quest.title)
                                        .foregroundStyle(progressStore.isQuestComplete(quest.slug) ? themeManager.colors.secondaryText : themeManager.colors.primaryText)
                                        .strikethrough(progressStore.isQuestComplete(quest.slug))
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    progressStore.toggleQuest(quest.slug)
                                } label: {
                                    Label(
                                        progressStore.isQuestComplete(quest.slug) ? "Undo" : "Done",
                                        systemImage: progressStore.isQuestComplete(quest.slug) ? "arrow.uturn.backward" : "checkmark"
                                    )
                                }
                                .tint(progressStore.isQuestComplete(quest.slug) ? .gray : .green)
                            }
                            .listRowBackground(themeManager.colors.cardBackground)
                        }
                    } header: {
                        Text("Quest Order")
                            .foregroundStyle(themeManager.colors.sectionLabel)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                .toolbar(.hidden, for: .navigationBar)
            }
            .background(themeManager.colors.background)
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 9.2: Commit**

```bash
git add app/Sources/Views/WalkthroughTab/WalkthroughTabView.swift
git commit -m "feat: Walkthrough tab — compact header"
```

---

## Task 10: Update ProgressTabView (compact header only)

**Files:**
- Modify: `app/Sources/Views/ProgressTab/ProgressTabView.swift`

- [ ] **Step 10.1: Replace the toolbar block**

Remove the entire `.toolbar { ... }`, `.toolbarBackground(...)` (both lines) blocks from the existing file. Then add `.toolbar(.hidden, for: .navigationBar)` immediately after `.background(themeManager.colors.background)` on the List.

Then wrap the existing `NavigationStack { List { ... } }` in a `VStack(spacing: 0)` that starts with `TabHeaderView(title: "Progress", showingSettings: $showingSettings).environmentObject(themeManager)`.

The resulting structure is:

```swift
// ProgressTabView.swift — Completion stats and progress reset.
import SwiftUI

struct ProgressTabView: View {
    @EnvironmentObject private var contentStore: ContentStore
    @EnvironmentObject private var progressStore: ProgressStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingResetConfirm = false
    @State private var showingSettings = false

    private var completedMainCount: Int {
        contentStore.quests.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    private var completedSideCount: Int {
        contentStore.sideQuests.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    private var completedAdventureCount: Int {
        contentStore.adventures.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    private var completedShrineCount: Int {
        contentStore.shrines.filter { progressStore.isQuestComplete($0.slug) }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabHeaderView(title: "Progress", showingSettings: $showingSettings)
                    .environmentObject(themeManager)

                List {
                    Section {
                        LabeledContent("Completed", value: "\(completedMainCount) / \(contentStore.quests.count)")
                            .foregroundStyle(themeManager.colors.primaryText)
                            .listRowBackground(themeManager.colors.cardBackground)
                        if contentStore.quests.count > 0 {
                            ProgressView(value: Double(completedMainCount), total: Double(contentStore.quests.count))
                                .tint(themeManager.colors.progressFill)
                                .listRowBackground(themeManager.colors.cardBackground)
                        }
                    } header: {
                        Text("Main Quests").foregroundStyle(themeManager.colors.sectionLabel)
                    }

                    Section {
                        LabeledContent("Completed", value: "\(completedSideCount) / \(contentStore.sideQuests.count)")
                            .foregroundStyle(themeManager.colors.primaryText)
                            .listRowBackground(themeManager.colors.cardBackground)
                        if contentStore.sideQuests.count > 0 {
                            ProgressView(value: Double(completedSideCount), total: Double(contentStore.sideQuests.count))
                                .tint(themeManager.colors.progressFill)
                                .listRowBackground(themeManager.colors.cardBackground)
                        }
                    } header: {
                        Text("Side Quests").foregroundStyle(themeManager.colors.sectionLabel)
                    }

                    Section {
                        LabeledContent("Completed", value: "\(completedAdventureCount) / \(contentStore.adventures.count)")
                            .foregroundStyle(themeManager.colors.primaryText)
                            .listRowBackground(themeManager.colors.cardBackground)
                        if contentStore.adventures.count > 0 {
                            ProgressView(value: Double(completedAdventureCount), total: Double(contentStore.adventures.count))
                                .tint(themeManager.colors.progressFill)
                                .listRowBackground(themeManager.colors.cardBackground)
                        }
                    } header: {
                        Text("Adventures").foregroundStyle(themeManager.colors.sectionLabel)
                    }

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

                    Section {
                        Button("Reset All Progress", role: .destructive) {
                            showingResetConfirm = true
                        }
                        .listRowBackground(themeManager.colors.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(themeManager.colors.background)
                .toolbar(.hidden, for: .navigationBar)
            }
            .background(themeManager.colors.background)
            .confirmationDialog("Reset all progress?",
                                isPresented: $showingResetConfirm,
                                titleVisibility: .visible) {
                Button("Reset", role: .destructive) { progressStore.reset() }
            } message: {
                Text("This will clear all completed quests and your bookmark.")
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet().environmentObject(themeManager)
            }
        }
    }
}
```

- [ ] **Step 10.2: Commit**

```bash
git add app/Sources/Views/ProgressTab/ProgressTabView.swift
git commit -m "feat: Progress tab — compact header"
```

---

## Task 11: Push all commits and trigger R10 IPA build

- [ ] **Step 11.1: Push to remote**

```bash
git push origin main
```

- [ ] **Step 11.2: Trigger build-ipa workflow**

```bash
gh workflow run build-ipa.yml \
  --field release=R10 \
  --field model_variant=1B
```

- [ ] **Step 11.3: Monitor build**

```bash
gh run list --workflow=build-ipa.yml --limit 3
```

Wait for the run to complete (usually ~5 minutes on macos-15). Once green, the IPA artifact `TOTKWalkthrough-R10.ipa` will be downloadable from the Actions run page.
