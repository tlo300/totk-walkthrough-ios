"""Run once to generate test fixtures: python scripts/tests/create_fixtures.py"""
from pathlib import Path
from docx import Document
from docx.shared import Pt

fixtures = Path(__file__).parent / "fixtures"
fixtures.mkdir(exist_ok=True)

# quest-order.docx: a numbered list of quest titles
doc = Document()
for title in ["Find Princess Zelda", "Visit Purahs Lab", "Reach Hyrule Castle"]:
    p = doc.add_paragraph(title)
    p.style = doc.styles["List Number"]
doc.save(str(fixtures / "quest-order.docx"))
print("Created quest-order.docx")
