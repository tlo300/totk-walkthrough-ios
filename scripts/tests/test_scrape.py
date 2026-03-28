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


def test_slugify_url_trailing_slash():
    from scripts.scrape import slugify_url
    assert slugify_url("https://www.ign.com/wikis/totk/Ukouh_Shrine/") == "ukouh-shrine"


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


def test_html_to_markdown_table_cells_on_separate_lines():
    from scripts.scrape import html_to_markdown
    html = "<table><tr><th>Item</th><th>Location</th></tr></table>"
    result = html_to_markdown(html)
    lines = [l.strip() for l in result.splitlines() if l.strip()]
    assert "Item" in lines
    assert "Location" in lines


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
    html = "".join(f'<img src="https://cdn.ign.com/img{i}.jpg"/>' for i in range(1, 4))
    download_images(session, html, tmp_path, delay=0)
    assert (tmp_path / "image-001.jpg").exists()
    assert (tmp_path / "image-002.jpg").exists()
    assert (tmp_path / "image-003.jpg").exists()


def test_download_images_no_images_returns_unchanged_html(tmp_path):
    from scripts.scrape import download_images
    session = requests.Session()
    html = "<p>No images here.</p>"
    result = download_images(session, html, tmp_path, delay=0)
    assert result == html


@responses_lib.activate
def test_download_images_skips_failed_download(tmp_path):
    from scripts.scrape import download_images
    responses_lib.add(
        responses_lib.GET,
        "https://cdn.ign.com/broken.jpg",
        status=404,
    )
    session = requests.Session()
    html = '<img src="https://cdn.ign.com/broken.jpg" />'
    # Should not raise — failed download is logged and skipped
    result = download_images(session, html, tmp_path, delay=0)
    # File should NOT be saved
    assert not list(tmp_path.glob("image-*.jpg"))
    # The src should remain unchanged (download failed, no local file to point to)
    assert "broken.jpg" in result or "cdn.ign.com" in result
