import json
from pathlib import Path
import pytest

FIXTURES = Path(__file__).parent / "fixtures"

# ── Quest order ──────────────────────────────────────────────────────────────

def test_parse_quest_order_returns_correct_slugs():
    from scripts.convert import parse_quest_order
    result = parse_quest_order(FIXTURES / "quest-order.docx")
    slugs = [q["slug"] for q in result["quests"]]
    assert slugs == ["find-princess-zelda", "visit-purahs-lab", "reach-hyrule-castle"]

def test_parse_quest_order_returns_correct_titles():
    from scripts.convert import parse_quest_order
    result = parse_quest_order(FIXTURES / "quest-order.docx")
    titles = [q["title"] for q in result["quests"]]
    assert titles == ["Find Princess Zelda", "Visit Purahs Lab", "Reach Hyrule Castle"]

def test_parse_quest_order_sets_type_main():
    from scripts.convert import parse_quest_order
    result = parse_quest_order(FIXTURES / "quest-order.docx")
    assert all(q["type"] == "main" for q in result["quests"])

def test_parse_quest_order_side_quests_empty_by_default():
    from scripts.convert import parse_quest_order
    result = parse_quest_order(FIXTURES / "quest-order.docx")
    assert result["sideQuests"] == []
