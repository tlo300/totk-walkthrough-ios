# Content Scraper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `scripts/scrape.py`, a YAML-driven scraper that fetches IGN walkthrough pages and writes them into the app's existing content format.

**Architecture:** A single `scripts/scrape.py` module with pure functions for each stage (config loading, index parsing, detail extraction, image downloading, Markdown conversion) orchestrated by a `scrape()` function invoked via the CLI. All HTTP is mocked in tests using the `responses` library.

**Tech Stack:** Python 3.10+, requests, beautifulsoup4, html2text, pyyaml, responses (test only)

---

## File Map

| File | Status | Purpose |
|------|--------|---------|
| `requirements.txt` | Modify | Add scrape + test deps |
| `scripts/scrape.py` | Create | All scraper logic + CLI entry point |
| `scripts/scrapers/shrines.yaml` | Create | Config for shrine content source |
| `scripts/scrapers/side-quests.yaml` | Create | Config for side-quest content source |
| `scripts/tests/test_scrape.py` | Create | Unit + integration tests |

No changes to `convert.py`, `prepare_content.py`, or any Swift files.

---

### Task 1: Add Dependencies

**Files:**
- Modify: `requirements.txt`

- [ ] **Step 1: Add scrape and test dependencies to requirements.txt**

Open `requirements.txt` and replace with:

```
python-docx==1.1.2
pytest==8.1.1
pytest-cov==5.0.0
requests==2.32.3
beautifulsoup4==4.12.3
html2text==2024.2.26
pyyaml==6.0.2
responses==0.25.3
```

- [ ] **Step 2: Install the new dependencies**

```bash
.venv/Scripts/pip install requests==2.32.3 beautifulsoup4==4.12.3 html2text==2024.2.26 pyyaml==6.0.2 responses==0.25.3
```

Expected: all packages installed without errors.

- [ ] **Step 3: Verify imports work**

```bash
.venv/Scripts/python -c "import requests, bs4, html2text, yaml, responses; print('OK')"
```

Expected output: `OK`

- [ ] **Step 4: Commit**

```bash
git add requirements.txt
git commit -m "chore: add scraper dependencies"
```

---

### Task 2: load_config

**Files:**
- Create: `scripts/scrape.py`
- Create: `scripts/tests/test_scrape.py`

- [ ] **Step 1: Write the failing tests**

Create `scripts/tests/test_scrape.py`:

```python
"""Tests for scripts/scrape.py — all HTTP is mocked via the responses library."""
import json
from pathlib import Path
import pytest
import responses as responses_lib


# ── load_config ───────────────────────────────────────────────────────────────

def test_load_config_returns_dict(tmp_path):
    from scripts.scrape import load_config
    cfg_file = tmp_path / "test.yaml"
    cfg_file.write_text("""
index_url: "https://www.ign.com/wikis/totk/Shrines"
content_type: "shrine"
output_dir: "app/Resources/Content/shrines"
item_links: "a[data-cy='styled-link']"
title_selector: "h1"
content_area: "div.wiki-page-container"
delay_seconds: 1.5
""")
    cfg = load_config(cfg_file)
    assert cfg["content_type"] == "shrine"
    assert cfg["delay_seconds"] == 1.5


def test_load_config_missing_field_raises(tmp_path):
    from scripts.scrape import load_config
    cfg_file = tmp_path / "bad.yaml"
    cfg_file.write_text("index_url: https://example.com\n")  # missing required fields
    with pytest.raises(ValueError, match="Missing required config fields"):
        load_config(cfg_file)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py::test_load_config_returns_dict scripts/tests/test_scrape.py::test_load_config_missing_field_raises -v
```

Expected: both FAIL with `ModuleNotFoundError` or `ImportError` (scrape.py doesn't exist yet).

- [ ] **Step 3: Create scripts/scrape.py with load_config**

Create `scripts/scrape.py`:

```python
"""Scrape IGN walkthrough pages into the app's content format.

Usage:
    python -m scripts.scrape scripts/scrapers/shrines.yaml
"""
from __future__ import annotations

import json
import time
from pathlib import Path, PurePosixPath
from urllib.parse import urljoin, urlparse

import requests
import yaml
from bs4 import BeautifulSoup
import html2text as html2text_lib


_REQUIRED_FIELDS = {
    "index_url", "content_type", "output_dir",
    "item_links", "content_area", "delay_seconds",
}


def load_config(path: Path) -> dict:
    """Load and validate a YAML scraper config file."""
    cfg = yaml.safe_load(path.read_text(encoding="utf-8"))
    missing = _REQUIRED_FIELDS - cfg.keys()
    if missing:
        raise ValueError(f"Missing required config fields: {sorted(missing)}")
    return cfg
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py::test_load_config_returns_dict scripts/tests/test_scrape.py::test_load_config_missing_field_raises -v
```

Expected: both PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/scrape.py scripts/tests/test_scrape.py
git commit -m "feat: add load_config with required-field validation"
```

---

### Task 3: collect_items (Index Page Parsing)

**Files:**
- Modify: `scripts/scrape.py`
- Modify: `scripts/tests/test_scrape.py`

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_scrape.py`:

```python
# ── collect_items ─────────────────────────────────────────────────────────────

_INDEX_HTML = """
<html><body>
  <a data-cy="styled-link" href="/wikis/totk/Ukouh_Shrine">Ukouh Shrine</a>
  <a data-cy="styled-link" href="/wikis/totk/Gutanbac_Shrine">Gutanbac Shrine</a>
  <a href="/wikis/totk/Other">Should be ignored</a>
</body></html>
"""

def test_collect_items_returns_correct_count():
    from scripts.scrape import collect_items
    items = collect_items(_INDEX_HTML, "a[data-cy='styled-link']", "https://www.ign.com")
    assert len(items) == 2


def test_collect_items_titles():
    from scripts.scrape import collect_items
    items = collect_items(_INDEX_HTML, "a[data-cy='styled-link']", "https://www.ign.com")
    assert items[0][0] == "Ukouh Shrine"
    assert items[1][0] == "Gutanbac Shrine"


def test_collect_items_absolute_urls():
    from scripts.scrape import collect_items
    items = collect_items(_INDEX_HTML, "a[data-cy='styled-link']", "https://www.ign.com")
    assert items[0][1] == "https://www.ign.com/wikis/totk/Ukouh_Shrine"
    assert items[1][1] == "https://www.ign.com/wikis/totk/Gutanbac_Shrine"


def test_collect_items_ignores_non_matching_links():
    from scripts.scrape import collect_items
    items = collect_items(_INDEX_HTML, "a[data-cy='styled-link']", "https://www.ign.com")
    urls = [u for _, u in items]
    assert not any("Other" in u for u in urls)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "collect_items" -v
```

Expected: all FAIL with `ImportError`.

- [ ] **Step 3: Add collect_items to scripts/scrape.py**

Add after `load_config`:

```python
def collect_items(html: str, selector: str, base_url: str) -> list[tuple[str, str]]:
    """Parse the index page HTML and return (title, absolute_url) pairs.

    Only links matching selector are returned. Relative hrefs are resolved
    against base_url (e.g. "https://www.ign.com").
    """
    soup = BeautifulSoup(html, "html.parser")
    items = []
    for a in soup.select(selector):
        href = a.get("href", "").strip()
        if not href:
            continue
        title = a.get_text(strip=True)
        absolute_url = urljoin(base_url, href)
        items.append((title, absolute_url))
    return items
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "collect_items" -v
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/scrape.py scripts/tests/test_scrape.py
git commit -m "feat: add collect_items for index page parsing"
```

---

### Task 4: slugify_url

**Files:**
- Modify: `scripts/scrape.py`
- Modify: `scripts/tests/test_scrape.py`

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_scrape.py`:

```python
# ── slugify_url ───────────────────────────────────────────────────────────────

def test_slugify_url_basic():
    from scripts.scrape import slugify_url
    assert slugify_url("https://www.ign.com/wikis/totk/Ukouh_Shrine") == "ukouh-shrine"


def test_slugify_url_underscores_become_hyphens():
    from scripts.scrape import slugify_url
    assert slugify_url("https://www.ign.com/wikis/totk/Gutanbac_Shrine") == "gutanbac-shrine"


def test_slugify_url_already_hyphenated():
    from scripts.scrape import slugify_url
    assert slugify_url("https://www.ign.com/wikis/totk/side-quests") == "side-quests"


def test_slugify_url_lowercases():
    from scripts.scrape import slugify_url
    assert slugify_url("https://www.ign.com/wikis/totk/BIGNAME") == "bigname"
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "slugify_url" -v
```

Expected: all FAIL with `ImportError`.

- [ ] **Step 3: Add slugify_url to scripts/scrape.py**

Add after `collect_items`:

```python
def slugify_url(url: str) -> str:
    """Derive a slug from the final path segment of a URL.

    "https://www.ign.com/wikis/totk/Ukouh_Shrine" → "ukouh-shrine"
    """
    path = urlparse(url).path
    stem = PurePosixPath(path).name
    return stem.lower().replace("_", "-")
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "slugify_url" -v
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/scrape.py scripts/tests/test_scrape.py
git commit -m "feat: add slugify_url"
```

---

### Task 5: extract_title and extract_content_html

**Files:**
- Modify: `scripts/scrape.py`
- Modify: `scripts/tests/test_scrape.py`

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_scrape.py`:

```python
# ── extract_title / extract_content_html ──────────────────────────────────────

_DETAIL_HTML = """
<html><body>
  <h1>Ukouh Shrine</h1>
  <div class="wiki-page-container">
    <section class="wiki-section wiki-html">
      <h2>Walkthrough</h2>
      <p>Enter the shrine and interact with the Steward Construct.</p>
    </section>
    <section class="wiki-section wiki-html">
      <p>Use Ultrahand to lift the stone slab.</p>
    </section>
  </div>
  <div class="sidebar">Should not appear in output</div>
</body></html>
"""

def test_extract_title_from_selector():
    from scripts.scrape import extract_title
    assert extract_title(_DETAIL_HTML, "h1", "fallback") == "Ukouh Shrine"


def test_extract_title_falls_back_when_selector_missing():
    from scripts.scrape import extract_title
    assert extract_title(_DETAIL_HTML, "h99", "fallback title") == "fallback title"


def test_extract_content_html_returns_container_html():
    from scripts.scrape import extract_content_html
    result = extract_content_html(_DETAIL_HTML, "div.wiki-page-container")
    assert "Enter the shrine" in result
    assert "Use Ultrahand" in result


def test_extract_content_html_excludes_outside_elements():
    from scripts.scrape import extract_content_html
    result = extract_content_html(_DETAIL_HTML, "div.wiki-page-container")
    assert "Should not appear in output" not in result


def test_extract_content_html_returns_empty_string_when_selector_missing():
    from scripts.scrape import extract_content_html
    result = extract_content_html("<html><body><p>hi</p></body></html>", "div.missing")
    assert result == ""
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "extract_title or extract_content_html" -v
```

Expected: all FAIL with `ImportError`.

- [ ] **Step 3: Add both functions to scripts/scrape.py**

Add after `slugify_url`:

```python
def extract_title(html: str, selector: str, fallback: str) -> str:
    """Extract the page title using selector, or return fallback if not found."""
    soup = BeautifulSoup(html, "html.parser")
    el = soup.select_one(selector)
    return el.get_text(strip=True) if el else fallback


def extract_content_html(html: str, selector: str) -> str:
    """Return the outer HTML of the first element matching selector, or "" if not found."""
    soup = BeautifulSoup(html, "html.parser")
    el = soup.select_one(selector)
    return str(el) if el else ""
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "extract_title or extract_content_html" -v
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/scrape.py scripts/tests/test_scrape.py
git commit -m "feat: add extract_title and extract_content_html"
```

---

### Task 6: html_to_markdown

**Files:**
- Modify: `scripts/scrape.py`
- Modify: `scripts/tests/test_scrape.py`

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_scrape.py`:

```python
# ── html_to_markdown ──────────────────────────────────────────────────────────

def test_html_to_markdown_paragraph():
    from scripts.scrape import html_to_markdown
    result = html_to_markdown("<p>Enter the shrine and interact.</p>")
    assert "Enter the shrine and interact." in result


def test_html_to_markdown_h2_heading():
    from scripts.scrape import html_to_markdown
    result = html_to_markdown("<h2>Walkthrough</h2><p>Some text.</p>")
    assert "## Walkthrough" in result


def test_html_to_markdown_h3_heading():
    from scripts.scrape import html_to_markdown
    result = html_to_markdown("<h3>Puzzle 1</h3><p>Details.</p>")
    assert "### Puzzle 1" in result


def test_html_to_markdown_image_no_alt_text():
    from scripts.scrape import html_to_markdown
    result = html_to_markdown('<img src="image-001.jpeg" alt="A shrine interior" />')
    assert "![](image-001.jpeg)" in result
    assert "A shrine interior" not in result


def test_html_to_markdown_image_no_alt_attribute():
    from scripts.scrape import html_to_markdown
    result = html_to_markdown('<img src="image-002.jpeg" />')
    assert "![](image-002.jpeg)" in result


def test_html_to_markdown_table_plain_text_no_pipes():
    from scripts.scrape import html_to_markdown
    html = """<table>
      <tr><th>Item</th><th>Location</th></tr>
      <tr><td>Bow</td><td>Chest</td></tr>
    </table>"""
    result = html_to_markdown(html)
    assert "Item" in result
    assert "Location" in result
    assert "Bow" in result
    assert "Chest" in result
    assert "|" not in result  # no markdown table pipe syntax


def test_html_to_markdown_strips_links():
    from scripts.scrape import html_to_markdown
    result = html_to_markdown('<p>See <a href="https://example.com">this page</a>.</p>')
    assert "this page" in result
    assert "https://example.com" not in result
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "html_to_markdown" -v
```

Expected: all FAIL with `ImportError`.

- [ ] **Step 3: Add html_to_markdown to scripts/scrape.py**

Add after `extract_content_html`:

```python
def html_to_markdown(html: str) -> str:
    """Convert content area HTML to Markdown per spec rules.

    - Paragraphs and headings are preserved as Markdown
    - Images become ![](src) — alt text is stripped
    - Tables become plain text (each cell on its own line, rows separated by blank lines)
    - Links are stripped (text preserved, URLs removed)
    """
    soup = BeautifulSoup(html, "html.parser")

    # Convert tables to plain text before passing to html2text
    for table in soup.find_all("table"):
        rows = []
        for tr in table.find_all("tr"):
            cells = [cell.get_text(strip=True) for cell in tr.find_all(["td", "th"])]
            non_empty = [c for c in cells if c]
            if non_empty:
                rows.append("\n".join(non_empty))
        replacement = soup.new_tag("div")
        replacement.string = "\n\n".join(rows)
        table.replace_with(replacement)

    # Strip alt attributes so html2text outputs ![](src) with no alt text
    for img in soup.find_all("img"):
        img.attrs.pop("alt", None)

    converter = html2text_lib.HTML2Text()
    converter.ignore_links = True
    converter.ignore_images = False
    converter.body_width = 0  # no line wrapping

    return converter.handle(str(soup)).strip()
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "html_to_markdown" -v
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/scrape.py scripts/tests/test_scrape.py
git commit -m "feat: add html_to_markdown with table and image handling"
```

---

### Task 7: download_images

**Files:**
- Modify: `scripts/scrape.py`
- Modify: `scripts/tests/test_scrape.py`

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_scrape.py`:

```python
# ── download_images ───────────────────────────────────────────────────────────

@responses_lib.activate
def test_download_images_saves_file(tmp_path):
    from scripts.scrape import download_images
    responses_lib.add(
        responses_lib.GET,
        "https://cdn.ign.com/shrine.jpg",
        body=b"\xff\xd8\xff\xe0fake",
        content_type="image/jpeg",
    )
    session = requests.Session()
    html = '<img src="https://cdn.ign.com/shrine.jpg" />'
    download_images(session, html, tmp_path, delay=0)
    assert (tmp_path / "image-001.jpg").exists()


@responses_lib.activate
def test_download_images_rewrites_src(tmp_path):
    from scripts.scrape import download_images
    responses_lib.add(
        responses_lib.GET,
        "https://cdn.ign.com/img1.jpg",
        body=b"fakejpeg",
        content_type="image/jpeg",
    )
    responses_lib.add(
        responses_lib.GET,
        "https://cdn.ign.com/img2.png",
        body=b"fakepng",
        content_type="image/png",
    )
    session = requests.Session()
    html = '<p><img src="https://cdn.ign.com/img1.jpg"/><img src="https://cdn.ign.com/img2.png"/></p>'
    result = download_images(session, html, tmp_path, delay=0)
    assert 'src="image-001.jpg"' in result
    assert 'src="image-002.png"' in result
    assert "cdn.ign.com" not in result


@responses_lib.activate
def test_download_images_sequential_naming(tmp_path):
    from scripts.scrape import download_images
    for i in range(1, 4):
        responses_lib.add(
            responses_lib.GET,
            f"https://cdn.ign.com/img{i}.jpg",
            body=b"fake",
        )
    session = requests.Session()
    html = ''.join(f'<img src="https://cdn.ign.com/img{i}.jpg"/>' for i in range(1, 4))
    download_images(session, html, tmp_path, delay=0)
    assert (tmp_path / "image-001.jpg").exists()
    assert (tmp_path / "image-002.jpg").exists()
    assert (tmp_path / "image-003.jpg").exists()


@responses_lib.activate
def test_download_images_no_images_returns_unchanged_html(tmp_path):
    from scripts.scrape import download_images
    session = requests.Session()
    html = "<p>No images here.</p>"
    result = download_images(session, html, tmp_path, delay=0)
    assert result == html
```

Add `import requests` near the top of the test file (after the existing imports).

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "download_images" -v
```

Expected: all FAIL with `ImportError`.

- [ ] **Step 3: Add download_images to scripts/scrape.py**

Add after `html_to_markdown`:

```python
def download_images(
    session: requests.Session,
    content_html: str,
    out_dir: Path,
    delay: float,
) -> str:
    """Download all images referenced in content_html into out_dir.

    Images are renamed image-001.ext, image-002.ext, etc. Returns modified
    HTML with src attributes updated to the new filenames.
    """
    soup = BeautifulSoup(content_html, "html.parser")
    images = soup.find_all("img")
    if not images:
        return content_html

    out_dir.mkdir(parents=True, exist_ok=True)
    for i, img in enumerate(images, start=1):
        src = img.get("src", "").strip()
        if not src:
            continue
        ext = Path(urlparse(src).path).suffix or ".jpg"
        filename = f"image-{i:03d}{ext}"
        time.sleep(delay)
        try:
            resp = session.get(src, headers={"User-Agent": "TOTK-Walkthrough-Scraper/1.0"}, timeout=30)
            resp.raise_for_status()
            (out_dir / filename).write_bytes(resp.content)
            print(f"  Saved: {filename}")
        except Exception as exc:
            print(f"  WARNING: could not download {src}: {exc}")
            continue
        img["src"] = filename

    return str(soup)
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "download_images" -v
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/scrape.py scripts/tests/test_scrape.py
git commit -m "feat: add download_images with sequential renaming"
```

---

### Task 8: scrape Orchestrator + CLI

**Files:**
- Modify: `scripts/scrape.py`
- Modify: `scripts/tests/test_scrape.py`

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_scrape.py`:

```python
# ── scrape (integration) ──────────────────────────────────────────────────────

def _write_config(tmp_path, output_dir, extra=""):
    cfg = tmp_path / "test.yaml"
    cfg.write_text(f"""
index_url: "https://www.ign.com/wikis/totk/Shrines"
content_type: "shrine"
output_dir: "{output_dir.as_posix()}"
item_links: "a[data-cy='styled-link']"
title_selector: "h1"
content_area: "div.wiki-page-container"
delay_seconds: 0
{extra}
""")
    return cfg


_INDEX_PAGE = """<html><body>
  <a data-cy="styled-link" href="/wikis/totk/Ukouh_Shrine">Ukouh Shrine</a>
</body></html>"""

_DETAIL_PAGE = """<html><body>
  <h1>Ukouh Shrine</h1>
  <div class="wiki-page-container">
    <p>Enter the shrine and interact with the Steward Construct.</p>
  </div>
</body></html>"""


@responses_lib.activate
def test_scrape_writes_index_json(tmp_path):
    from scripts.scrape import scrape
    output_dir = tmp_path / "output"
    cfg = _write_config(tmp_path, output_dir)
    responses_lib.add(responses_lib.GET, "https://www.ign.com/wikis/totk/Shrines", body=_INDEX_PAGE)
    responses_lib.add(responses_lib.GET, "https://www.ign.com/wikis/totk/Ukouh_Shrine", body=_DETAIL_PAGE)
    scrape(cfg)
    assert (output_dir / "index.json").exists()
    idx = json.loads((output_dir / "index.json").read_text())
    assert idx["quests"][0]["slug"] == "ukouh-shrine"
    assert idx["quests"][0]["title"] == "Ukouh Shrine"
    assert idx["quests"][0]["type"] == "shrine"
    assert idx["quests"][0]["id"] == 1
    assert idx["sideQuests"] == []


@responses_lib.activate
def test_scrape_writes_content_md(tmp_path):
    from scripts.scrape import scrape
    output_dir = tmp_path / "output"
    cfg = _write_config(tmp_path, output_dir)
    responses_lib.add(responses_lib.GET, "https://www.ign.com/wikis/totk/Shrines", body=_INDEX_PAGE)
    responses_lib.add(responses_lib.GET, "https://www.ign.com/wikis/totk/Ukouh_Shrine", body=_DETAIL_PAGE)
    scrape(cfg)
    md = (output_dir / "ukouh-shrine" / "content.md").read_text(encoding="utf-8")
    assert "Enter the shrine and interact with the Steward Construct." in md


@responses_lib.activate
def test_scrape_skips_existing_items(tmp_path):
    from scripts.scrape import scrape
    output_dir = tmp_path / "output"
    cfg = _write_config(tmp_path, output_dir)

    # Pre-create content.md so scraper should skip this item
    slug_dir = output_dir / "ukouh-shrine"
    slug_dir.mkdir(parents=True)
    (slug_dir / "content.md").write_text("pre-existing")

    responses_lib.add(responses_lib.GET, "https://www.ign.com/wikis/totk/Shrines", body=_INDEX_PAGE)
    # No detail page mock — if scraper fetches it, responses raises ConnectionError

    scrape(cfg)

    # content.md must be untouched
    assert (output_dir / "ukouh-shrine" / "content.md").read_text() == "pre-existing"
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "test_scrape_" -v
```

Expected: all FAIL with `ImportError`.

- [ ] **Step 3: Add scrape() and __main__ block to scripts/scrape.py**

Add at the end of `scripts/scrape.py`:

```python
def _fetch(session: requests.Session, url: str, delay: float) -> requests.Response:
    """Sleep for delay seconds, then GET url. Raises on HTTP errors."""
    time.sleep(delay)
    resp = session.get(url, headers={"User-Agent": "TOTK-Walkthrough-Scraper/1.0"}, timeout=30)
    resp.raise_for_status()
    print(f"Fetched: {url}")
    return resp


def scrape(config_path: Path) -> None:
    """Run the full scrape pipeline defined by a YAML config file."""
    cfg = load_config(config_path)
    index_url: str = cfg["index_url"]
    content_type: str = cfg["content_type"]
    output_dir = Path(cfg["output_dir"])
    item_links_selector: str = cfg["item_links"]
    title_selector: str = cfg.get("title_selector", "h1")
    content_area_selector: str = cfg["content_area"]
    delay: float = float(cfg["delay_seconds"])
    base_url = f"{urlparse(index_url).scheme}://{urlparse(index_url).netloc}"

    session = requests.Session()

    # 1. Fetch index page and collect item links
    index_html = _fetch(session, index_url, delay=0).text
    items = collect_items(index_html, item_links_selector, base_url)
    print(f"Found {len(items)} items on index page.")

    index_entries: list[dict] = []

    # 2. Process each item
    for position, (link_title, detail_url) in enumerate(items, start=1):
        slug = slugify_url(detail_url)
        slug_dir = output_dir / slug

        if (slug_dir / "content.md").exists():
            print(f"Skipping {slug} (already exists)")
            index_entries.append({"id": position, "slug": slug, "title": link_title, "type": content_type})
            continue

        # Fetch detail page
        try:
            detail_html = _fetch(session, detail_url, delay=delay).text
        except Exception as exc:
            print(f"ERROR fetching {detail_url}: {exc} — skipping")
            continue

        title = extract_title(detail_html, title_selector, fallback=link_title)
        content_html = extract_content_html(detail_html, content_area_selector)
        if not content_html:
            print(f"WARNING: content_area selector '{content_area_selector}' found nothing on {detail_url}")

        slug_dir.mkdir(parents=True, exist_ok=True)
        content_html = download_images(session, content_html, slug_dir, delay=delay)
        markdown = html_to_markdown(content_html)

        (slug_dir / "content.md").write_text(markdown, encoding="utf-8")
        print(f"Wrote: {slug_dir / 'content.md'}")

        index_entries.append({"id": position, "slug": slug, "title": title, "type": content_type})

    # 3. Write index.json
    output_dir.mkdir(parents=True, exist_ok=True)
    index_data = {"quests": index_entries, "sideQuests": []}
    index_path = output_dir / "index.json"
    index_path.write_text(json.dumps(index_data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote: {index_path}")


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2:
        print("Usage: python -m scripts.scrape <config.yaml>")
        sys.exit(1)
    scrape(Path(sys.argv[1]))
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
.venv/Scripts/pytest scripts/tests/test_scrape.py -k "test_scrape_" -v
```

Expected: all PASS.

- [ ] **Step 5: Run the full test suite to check nothing regressed**

```bash
.venv/Scripts/pytest scripts/tests/ -v
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
git add scripts/scrape.py scripts/tests/test_scrape.py
git commit -m "feat: add scrape orchestrator and CLI entry point"
```

---

### Task 9: YAML Config Files

**Files:**
- Create: `scripts/scrapers/shrines.yaml`
- Create: `scripts/scrapers/side-quests.yaml`

- [ ] **Step 1: Create the scrapers directory and config files**

Create `scripts/scrapers/shrines.yaml`:

```yaml
index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/All_Shrine_Locations_and_Solutions"
content_type: "shrine"
output_dir: "app/Resources/Content/shrines"
item_links: "a[data-cy='styled-link']"
title_selector: "h1"
content_area: "div.wiki-page-container"
delay_seconds: 1.5
```

Create `scripts/scrapers/side-quests.yaml`:

```yaml
index_url: "https://www.ign.com/wikis/the-legend-of-zelda-tears-of-the-kingdom/Side_Quests"
content_type: "side-quest"
output_dir: "app/Resources/Content/side-quests"
item_links: "a[data-cy='styled-link']"
title_selector: "h1"
content_area: "div.wiki-page-container"
delay_seconds: 1.5
```

- [ ] **Step 2: Verify the configs load cleanly**

```bash
.venv/Scripts/python -c "
from pathlib import Path
from scripts.scrape import load_config
load_config(Path('scripts/scrapers/shrines.yaml'))
load_config(Path('scripts/scrapers/side-quests.yaml'))
print('Both configs valid')
"
```

Expected output: `Both configs valid`

- [ ] **Step 3: Commit**

```bash
git add scripts/scrapers/
git commit -m "feat: add shrines and side-quests YAML scraper configs"
```

---

## Final Verification

- [ ] **Run the complete test suite**

```bash
.venv/Scripts/pytest scripts/tests/ -v --tb=short
```

Expected: all tests PASS (test_convert.py + test_scrape.py).

- [ ] **Smoke-test the CLI help path**

```bash
.venv/Scripts/python -m scripts.scrape
```

Expected output:
```
Usage: python -m scripts.scrape <config.yaml>
```
