"""Scrape IGN walkthrough pages into the app's content format.

Usage:
    python -m scripts.scrape scripts/scrapers/shrines.yaml
"""
from __future__ import annotations

import json
import re
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


def collect_items(html: str, selector: str, base_url: str, section_heading: str | None = None) -> list[tuple[str, str]]:
    """Parse the index page HTML and return (title, absolute_url) pairs.

    Only links matching selector are returned. Relative hrefs are resolved
    against base_url (e.g. "https://www.ign.com").

    If section_heading is given, link collection is scoped to the nearest
    ancestor container of the first heading element whose text contains
    section_heading (case-insensitive). Falls back to sibling collection
    if the heading has no meaningful parent.
    """
    soup = BeautifulSoup(html, "html.parser")

    if section_heading:
        search_root = soup  # fallback
        needle = section_heading.lower()
        # Prefer an exact case-insensitive match; fall back to substring match.
        all_headings = soup.find_all(re.compile(r'^h[1-6]$'))
        matched_heading = next(
            (h for h in all_headings if h.get_text(strip=True).lower() == needle), None
        ) or next(
            (h for h in all_headings if needle in h.get_text(strip=True).lower()), None
        )
        if matched_heading is not None:
            level = int(matched_heading.name[1])
            parent = matched_heading.parent
            # If the heading's direct parent is a small wrapper (e.g. <section>
            # containing only the heading), use that parent's siblings as the
            # content scope.  Otherwise fall back to the heading's own siblings.
            heading_siblings = list(matched_heading.find_next_siblings())
            has_sibling_content = any(
                s for s in heading_siblings
                if getattr(s, 'name', None) and s.name not in ('html', 'body')
            )
            if not has_sibling_content and parent and parent.name not in ('html', 'body', '[document]'):
                # Walk siblings of the parent container
                scope_node = parent
            else:
                scope_node = matched_heading

            fragments: list[str] = []
            for sib in scope_node.find_next_siblings():
                # Stop if the sibling itself is a same-or-higher-level heading
                if sib.name and re.match(r'^h[1-6]$', sib.name) and int(sib.name[1]) <= level:
                    break
                # Stop if the sibling has a *direct child* heading at the same/higher level
                # (IGN wraps each section heading in its own <section> element)
                direct_heading = next(
                    (c for c in sib.children
                     if hasattr(c, 'name') and c.name and re.match(r'^h[1-6]$', c.name)
                     and int(c.name[1]) <= level),
                    None,
                ) if hasattr(sib, 'children') else None
                if direct_heading is not None:
                    break
                fragments.append(str(sib))
            if fragments:
                search_root = BeautifulSoup("".join(fragments), "html.parser")
    else:
        search_root = soup

    items = []
    for a in search_root.select(selector):
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
    slug = stem.lower().replace("_", "-")
    # Strip characters that are invalid in Windows directory names
    return re.sub(r'[<>:"/\\|?*]', "", slug)


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


def extract_oyster_image_map(page_html: str) -> dict[str, str]:
    """Return a mapping of {filename: url} for oyster.ignimgs.com images found in script tags.

    IGN lazy-loads images — the real URLs live in inline JS, not in img[src].
    This scans all <script> tags and indexes each URL by its filename component.
    """
    soup = BeautifulSoup(page_html, "html.parser")
    mapping: dict[str, str] = {}
    for script in soup.find_all("script"):
        content = script.string or ""
        for url in re.findall(r'https://oyster\.ignimgs\.com/[^\s"\']+\.(?:jpg|jpeg|png|webp|gif)', content):
            filename = PurePosixPath(urlparse(url).path).name
            mapping[filename] = url
    return mapping


def resolve_lazy_images(content_html: str, image_map: dict[str, str]) -> str:
    """Replace data: placeholder src attrs with real URLs.

    Strategy (in order):
    1. data-src attribute — IGN often stores the real URL here directly.
    2. alt attribute lookup in image_map — alt is set to the original filename
       (e.g. "TotK GreatSky 16.jpg"), normalised to underscores for the map key.

    Images with no match are left unchanged (download_images will remove them).
    """
    soup = BeautifulSoup(content_html, "html.parser")
    for img in soup.find_all("img"):
        src = img.get("src", "")
        if not src.startswith("data:"):
            continue
        # 1. data-src fallback
        data_src = img.get("data-src", "").strip()
        if data_src and not data_src.startswith("data:"):
            img["src"] = data_src
            continue
        # 2. alt-text image_map lookup
        if not image_map:
            continue
        alt = img.get("alt", "").strip()
        key = alt.replace(" ", "_")
        if key in image_map:
            img["src"] = image_map[key]
    return str(soup)


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
    counter = 0
    for img in images:
        src = img.get("src", "").strip()
        if not src or src.startswith("data:"):
            img.decompose()  # Remove placeholder/tracker images entirely
            continue
        counter += 1
        ext = Path(urlparse(src).path).suffix or ".jpg"
        filename = f"image-{counter:03d}{ext}"
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


def scrape(config_path: Path, limit: int | None = None) -> None:
    """Run the full scrape pipeline defined by a YAML config file."""
    cfg = load_config(config_path)
    index_url: str = cfg["index_url"]
    content_type: str = cfg["content_type"]
    output_dir = Path(cfg["output_dir"])
    item_links_selector: str = cfg["item_links"]
    section_heading: str | None = cfg.get("section_heading")
    title_selector: str = cfg.get("title_selector", "h1")
    title_strip: str = cfg.get("title_strip", "")
    content_area_selector: str = cfg["content_area"]
    delay: float = float(cfg["delay_seconds"])
    parsed = urlparse(index_url)
    base_url = f"{parsed.scheme}://{parsed.netloc}"

    session = requests.Session()

    # 1. Fetch index page and collect item links
    index_html = _fetch(session, index_url, delay=0).text
    items = collect_items(index_html, item_links_selector, base_url, section_heading=section_heading)
    # Deduplicate by URL — index pages sometimes link the same page multiple times
    seen: set[str] = set()
    items = [(t, u) for t, u in items if not (u in seen or seen.add(u))]  # type: ignore[func-returns-value]
    if limit:
        items = items[:limit]
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
        if title_strip and title.endswith(title_strip):
            title = title[: -len(title_strip)].strip()
        content_html = extract_content_html(detail_html, content_area_selector)
        if not content_html:
            print(f"WARNING: content_area selector '{content_area_selector}' found nothing on {detail_url}")

        slug_dir.mkdir(parents=True, exist_ok=True)
        image_map = extract_oyster_image_map(detail_html)
        content_html = resolve_lazy_images(content_html, image_map)
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
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("config", type=Path)
    parser.add_argument("--limit", type=int, default=None, help="Only scrape the first N items")
    args = parser.parse_args()
    scrape(args.config, limit=args.limit)
