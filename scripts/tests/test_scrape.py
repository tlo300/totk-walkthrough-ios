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
