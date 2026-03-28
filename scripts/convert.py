"""Convert TOTK walkthrough Word docs to Markdown + JSON for the iOS app bundle."""
from __future__ import annotations
import re
import json
import argparse
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
        if not text:
            continue

        if para.style.name == "Checkpoint":
            checkpoint_id = slugify(text)
            lines.append("~~~checkpoint")
            lines.append(f"id: {checkpoint_id}")
            lines.append(f"label: {text}")
            lines.append("~~~")
            lines.append("")
        else:
            lines.append(text)
            lines.append("")

    (output_dir / "content.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert TOTK walkthrough Word docs to app bundle content.")
    parser.add_argument("--content", type=Path, default=Path("content"),
                        help="Path to source content directory (default: content/)")
    parser.add_argument("--output", type=Path, default=Path("app/Resources/Content"),
                        help="Path to output directory (default: app/Resources/Content)")
    args = parser.parse_args()

    content_dir: Path = args.content
    output_dir: Path = args.output
    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. Parse quest order → quest-order.json
    quest_order_path = content_dir / "quest-order.docx"
    if not quest_order_path.exists():
        raise FileNotFoundError(f"Missing quest order doc: {quest_order_path}")
    quest_data = parse_quest_order(quest_order_path)

    # 2. Convert each main quest doc
    quests_src = content_dir / "quests"
    quests_out = output_dir / "quests"
    for quest in quest_data["quests"]:
        src = quests_src / f"{quest['slug']}.docx"
        if src.exists():
            convert_quest_doc(src, quests_out / quest["slug"])

    # 3. Convert each side quest doc
    side_src = content_dir / "side-quests"
    side_out = output_dir / "side-quests"
    for quest in quest_data["sideQuests"]:
        src = side_src / f"{quest['slug']}.docx"
        if src.exists():
            convert_quest_doc(src, side_out / quest["slug"])

    # 4. Write quest-order.json
    quest_order_out = output_dir / "quest-order.json"
    quest_order_out.write_text(json.dumps(quest_data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {quest_order_out}")


if __name__ == "__main__":
    main()
