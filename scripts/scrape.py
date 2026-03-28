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
