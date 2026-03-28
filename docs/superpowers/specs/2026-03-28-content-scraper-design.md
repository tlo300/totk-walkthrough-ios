# Content Scraper Design

## Overview

A YAML-driven Python scraper (`scripts/scrape.py`) that fetches walkthrough pages from IGN, extracts text and images, and writes them into the app's existing content format. One YAML config file per content source (shrines, side quests, etc.) drives the whole pipeline — no code changes needed to add a new source.

The scraper slots into the existing pipeline before `convert.py`: scrape → convert → build IPA.

## Config Format

One YAML file per content source, placed in `scripts/scrapers/`:

```yaml
index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/All_Shrine_Locations_and_Solutions"
content_type: "shrine"          # value used in index.json "type" field
output_dir: "app/Resources/Content/shrines"
item_links: "a[data-cy='styled-link']"   # CSS selector for links on the index page
title_selector: "h1"                     # CSS selector for title on detail pages
content_area: "div.wiki-page-container"  # CSS selector for content wrapper on detail pages
delay_seconds: 1.5
```

- `item_links` hrefs from IGN are relative — prepend `https://www.ign.com`
- `delay_seconds` enforces minimum pause between HTTP requests (respects crawl-delay)
- `content_type` is stored in `index.json` but not currently used by the iOS app (reserved)

## Directory Structure

```
scripts/
  scrape.py             # new generic scraper (this spec)
  scrapers/             # new — one YAML per content source
    shrines.yaml
    side-quests.yaml
  convert.py            # unchanged
  prepare_content.py    # unchanged
```

## scrape.py Flow

Invoked as: `python -m scripts.scrape scripts/scrapers/shrines.yaml`

1. Load and validate YAML config from CLI arg
2. Fetch index page → find all `item_links` → collect `(title, href)` pairs
3. For each item (with `delay_seconds` pause between requests):
   - Derive `slug` from the URL path final segment (lowercase, hyphens)
   - Skip if `{output_dir}/{slug}/content.md` already exists (resumable — safe to re-run)
   - Fetch detail page
   - Extract title: from `title_selector` if present, else fall back to index link text
   - Extract body from `content_area` element
   - Convert body HTML → Markdown (paragraphs, headings, inline images)
   - Download images into `{output_dir}/{slug}/`, rename sequentially: `image-001.jpeg`, `image-002.jpeg`, etc.
   - Write `{output_dir}/{slug}/content.md`
4. Write `{output_dir}/index.json`

## IGN HTML Selectors (Confirmed)

These selectors were verified against saved IGN HTML files in `content/sidequests/`:

| Purpose | Selector |
|---------|----------|
| Index page links | `a[data-cy="styled-link"]` |
| Detail page content wrapper | `div.wiki-page-container` |
| Title | `h1` |

The `div.wiki-page-container` element contains all `section.wiki-section.wiki-html` children which hold the structured walkthrough content (paragraphs, headings, images, tables).

## Output Format

Matches existing app content format exactly so `convert.py` needs no changes.

### `index.json`

```json
{
  "quests": [
    { "id": 1, "slug": "ukouh-shrine", "title": "Ukouh Shrine", "type": "shrine" }
  ],
  "sideQuests": []
}
```

- `id` is 1-based position in the scraped list
- `sideQuests` is always `[]` (not used by current app; main list drives display)

### `{slug}/content.md`

Plain Markdown matching the format `convert.py` already handles:

```markdown
## Ukouh Shrine — The Ability to Create

Enter the shrine and interact with the Steward Construct...

![](image-001.jpeg)

Use Ultrahand to lift the stone slab...
```

Rules:
- Paragraphs as plain text blocks separated by blank lines
- Headings preserved as `##` (h2) or `###` (h3)
- Images as `![](image-NNN.jpeg)` — no alt text, no captions
- No checkpoint markers (IGN content has no equivalent)
- Tables converted to plain text (each cell on its own line, rows separated by blank lines)
- Strip navigation, ads, infoboxes, and any element outside `div.wiki-page-container`

## HTTP Behaviour

- `requests` with a descriptive `User-Agent` header
- `delay_seconds` minimum between all requests (index + each detail page)
- No retry logic in v1 — if a page fails, log the error and skip; re-run to resume
- Log each URL fetched and each file written so progress is visible

## Dependencies

Add to `requirements.txt` (or `requirements-scrape.txt` if keeping scrape deps separate):

```
requests
beautifulsoup4
html2text
pyyaml
```

`html2text` handles HTML-to-Markdown conversion. `beautifulsoup4` for parsing. `pyyaml` for config.

## Example YAML Files

### `scripts/scrapers/shrines.yaml`

```yaml
index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/All_Shrine_Locations_and_Solutions"
content_type: "shrine"
output_dir: "app/Resources/Content/shrines"
item_links: "a[data-cy='styled-link']"
title_selector: "h1"
content_area: "div.wiki-page-container"
delay_seconds: 1.5
```

### `scripts/scrapers/side-quests.yaml`

```yaml
index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/Side_Quests"
content_type: "side-quest"
output_dir: "app/Resources/Content/side-quests"
item_links: "a[data-cy='styled-link']"
title_selector: "h1"
content_area: "div.wiki-page-container"
delay_seconds: 1.5
```

## Out of Scope

- No changes to `convert.py`, `prepare_content.py`, or any Swift code
- No authentication or session handling (IGN pages are public)
- No pagination on index pages (all shrine/quest links appear on a single page)
- No parallel fetching (sequential with delay is sufficient and polite)
