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
