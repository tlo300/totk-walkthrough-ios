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

import tempfile, shutil

# ── Quest doc conversion ──────────────────────────────────────────────────────

def test_convert_quest_doc_creates_content_md(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-sample.docx", tmp_path)
    assert (tmp_path / "content.md").exists()

def test_convert_quest_doc_content_contains_text(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-sample.docx", tmp_path)
    content = (tmp_path / "content.md").read_text(encoding="utf-8")
    assert "Head north from Lookout Landing" in content
    assert "Enter the underground passage" in content

def test_convert_quest_doc_extracts_image(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-sample.docx", tmp_path)
    images = list(tmp_path.glob("image-*.png"))
    assert len(images) == 1

def test_convert_quest_doc_image_reference_in_markdown(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-sample.docx", tmp_path)
    content = (tmp_path / "content.md").read_text(encoding="utf-8")
    assert "![](image-001.png)" in content

def test_convert_quest_doc_image_appears_between_paragraphs(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-sample.docx", tmp_path)
    content = (tmp_path / "content.md").read_text(encoding="utf-8")
    # Image should appear after the second paragraph, before the third
    idx_image = content.index("![](image-001.png)")
    idx_gloom = content.index("Watch out for Gloom Hands")
    idx_enter = content.index("Enter the underground passage")
    assert idx_gloom < idx_image < idx_enter

# ── Checkpoint detection ──────────────────────────────────────────────────────

def test_checkpoint_paragraph_emits_checkpoint_block(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-with-checkpoint.docx", tmp_path)
    content = (tmp_path / "content.md").read_text(encoding="utf-8")
    assert "~~~checkpoint" in content

def test_checkpoint_block_contains_label(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-with-checkpoint.docx", tmp_path)
    content = (tmp_path / "content.md").read_text(encoding="utf-8")
    assert "label: Reached the castle gates?" in content

def test_checkpoint_block_contains_id(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-with-checkpoint.docx", tmp_path)
    content = (tmp_path / "content.md").read_text(encoding="utf-8")
    assert "id: reached-the-castle-gates" in content

def test_checkpoint_text_not_emitted_as_plain_paragraph(tmp_path):
    from scripts.convert import convert_quest_doc
    convert_quest_doc(FIXTURES / "quest-with-checkpoint.docx", tmp_path)
    content = (tmp_path / "content.md").read_text(encoding="utf-8")
    # The raw checkpoint text should only appear inside the block, not as a bare paragraph
    lines = content.splitlines()
    bare = [l for l in lines if l.strip() == "Reached the castle gates?"]
    assert bare == []

import subprocess, sys

# ── CLI integration ───────────────────────────────────────────────────────────

def test_cli_produces_quest_order_json(tmp_path):
    """Full pipeline: given a content dir structure, CLI writes app bundle output."""
    # Set up a minimal content/ structure in tmp_path
    content_dir = tmp_path / "content"
    quest_dir = content_dir / "quests"
    quest_dir.mkdir(parents=True)
    import shutil
    shutil.copy(FIXTURES / "quest-order.docx", content_dir / "quest-order.docx")
    shutil.copy(FIXTURES / "quest-with-checkpoint.docx", quest_dir / "find-princess-zelda.docx")

    output_dir = tmp_path / "output"
    result = subprocess.run(
        [sys.executable, "-m", "scripts.convert",
         "--content", str(content_dir),
         "--output", str(output_dir)],
        capture_output=True, text=True
    )
    assert result.returncode == 0, result.stderr
    assert (output_dir / "quest-order.json").exists()
    assert (output_dir / "quests" / "find-princess-zelda" / "content.md").exists()
