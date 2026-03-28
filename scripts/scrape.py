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


def slugify_url(url: str) -> str:
    """Derive a slug from the final path segment of a URL.

    "https://www.ign.com/wikis/totk/Ukouh_Shrine" → "ukouh-shrine"
    Trailing slashes are stripped before extraction.
    """
    path = urlparse(url).path.rstrip("/")
    stem = PurePosixPath(path).name
    return stem.lower().replace("_", "-")


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


def html_to_markdown(html: str) -> str:
    """Convert content area HTML to Markdown per spec rules.

    - Paragraphs and headings are preserved as Markdown
    - Images become ![](src) — alt text is stripped
    - Tables become plain text (each cell on its own line, rows separated by blank lines)
    - Links are stripped (text preserved, URLs removed)
    """
    soup = BeautifulSoup(html, "html.parser")

    # Convert tables to plain text: one <p> per row, cells joined by <br>
    for table in soup.find_all("table"):
        container = soup.new_tag("div")
        for tr in table.find_all("tr"):
            cells = [cell.get_text(strip=True) for cell in tr.find_all(["td", "th"])]
            non_empty = [c for c in cells if c]
            if non_empty:
                p = soup.new_tag("p")
                for i, cell_text in enumerate(non_empty):
                    if i > 0:
                        p.append(soup.new_tag("br"))
                    p.append(cell_text)
                container.append(p)
        table.replace_with(container)

    # Strip alt attributes so html2text outputs ![](src) with no alt text
    for img in soup.find_all("img"):
        img.attrs.pop("alt", None)

    converter = html2text_lib.HTML2Text()
    converter.ignore_links = True
    converter.ignore_images = False
    converter.body_width = 0  # no line wrapping

    return converter.handle(str(soup)).strip()


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
        try:
            time.sleep(delay)
            resp = session.get(src, headers={"User-Agent": "TOTK-Walkthrough-Scraper/1.0"}, timeout=30)
            resp.raise_for_status()
            (out_dir / filename).write_bytes(resp.content)
            print(f"  Saved: {filename}")
        except Exception as exc:
            print(f"  WARNING: could not download {src}: {exc}")
            # Leave img["src"] unchanged — original URL stays in Markdown as best-effort fallback
            continue
        img["src"] = filename

    return str(soup)


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
    parsed = urlparse(index_url)
    base_url = f"{parsed.scheme}://{parsed.netloc}"

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
