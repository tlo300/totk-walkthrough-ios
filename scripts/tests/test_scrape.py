"""Tests for scripts/scrape.py — all HTTP is mocked via the responses library."""
import json
from pathlib import Path
import pytest
import requests
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
    cfg_file.write_text("index_url: https://example.com\n")
    with pytest.raises(ValueError, match="Missing required config fields"):
        load_config(cfg_file)


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
