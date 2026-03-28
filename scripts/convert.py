"""Convert TOTK walkthrough Word docs to Markdown + JSON for the iOS app bundle."""
from __future__ import annotations
import re
import json
from pathlib import Path
from docx import Document


def slugify(text: str) -> str:
    """Convert a title to a URL-safe slug: lowercase, spaces→hyphens, strip punctuation."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_]+", "-", text)
    return text.strip("-")


def parse_quest_order(docx_path: Path) -> dict:
    """Parse a quest-order.docx numbered list → quest-order.json structure.

    The docx should contain only non-empty paragraphs where each paragraph is
    a quest title. Leading numbers/bullets are stripped.
    """
    doc = Document(str(docx_path))
    quests = []
    for para in doc.paragraphs:
        text = para.text.strip()
        if not text:
            continue
        # Strip leading number like "1. " or "1) "
        title = re.sub(r"^\d+[\.\)]\s*", "", text).strip()
        if not title:
            continue
        quests.append({"slug": slugify(title), "title": title, "type": "main"})
    return {"quests": quests, "sideQuests": []}
