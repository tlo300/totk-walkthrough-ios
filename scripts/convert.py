"""Convert TOTK walkthrough Word docs to Markdown + JSON for the iOS app bundle."""
from __future__ import annotations
import re
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


from docx.oxml.ns import qn


def _paragraph_image_parts(para, doc_part):
    """Return list of image part objects for any images embedded in this paragraph."""
    blips = para._element.findall(".//" + qn("a:blip"))
    parts = []
    for blip in blips:
        rid = blip.get(qn("r:embed"))
        if rid and rid in doc_part.related_parts:
            parts.append(doc_part.related_parts[rid])
    return parts


def convert_quest_doc(docx_path: Path, output_dir: Path) -> None:
    """Convert a quest .docx to content.md + extracted images in output_dir."""
    output_dir.mkdir(parents=True, exist_ok=True)
    doc = Document(str(docx_path))
    lines: list[str] = []
    image_counter = 0

    for para in doc.paragraphs:
        # Check for embedded images in this paragraph
        image_parts = _paragraph_image_parts(para, doc.part)
        for img_part in image_parts:
            image_counter += 1
            ext = Path(img_part.partname).suffix or ".png"
            filename = f"image-{image_counter:03d}{ext}"
            (output_dir / filename).write_bytes(img_part.blob)
            lines.append(f"![]({filename})")
            lines.append("")

        text = para.text.strip()
        if text:
            lines.append(text)
            lines.append("")

    (output_dir / "content.md").write_text("\n".join(lines), encoding="utf-8")
