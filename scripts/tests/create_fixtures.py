"""Run once to generate test fixtures: python scripts/tests/create_fixtures.py"""
from pathlib import Path
from docx import Document

fixtures = Path(__file__).parent / "fixtures"
fixtures.mkdir(exist_ok=True)

# quest-order.docx: a numbered list of quest titles
doc = Document()
for title in ["Find Princess Zelda", "Visit Purahs Lab", "Reach Hyrule Castle"]:
    p = doc.add_paragraph(title)
    p.style = doc.styles["List Number"]
doc.save(str(fixtures / "quest-order.docx"))
print("Created quest-order.docx")

import urllib.request, io
from docx.shared import Inches

# quest-sample.docx: text, then an image, then more text
doc2 = Document()
doc2.add_paragraph("Head north from Lookout Landing along the main road.")
doc2.add_paragraph("Watch out for Gloom Hands near the castle gates.")

# Add a small synthetic image (1x1 white PNG, base64-encoded)
import base64
PNG_1X1 = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwADhQGAWjR9awAAAABJRU5ErkJggg=="
)
img_stream = io.BytesIO(PNG_1X1)
doc2.add_picture(img_stream, width=Inches(1))

doc2.add_paragraph("Enter the underground passage at the southeast corner.")
doc2.save(str(fixtures / "quest-sample.docx"))
print("Created quest-sample.docx")

# quest-with-checkpoint.docx: text, checkpoint, text
doc3 = Document()
doc3.add_paragraph("Head north from Lookout Landing.")

# Add a custom "Checkpoint" style
from docx.oxml.ns import qn as _qn
from docx.oxml import OxmlElement
styles = doc3.styles
try:
    cp_style = styles.add_style("Checkpoint", 1)  # 1 = WD_STYLE_TYPE.PARAGRAPH
except:
    cp_style = styles["Checkpoint"]
cp_style.base_style = styles["Normal"]

p = doc3.add_paragraph("Reached the castle gates?")
p.style = cp_style

doc3.add_paragraph("Enter the underground passage.")
doc3.save(str(fixtures / "quest-with-checkpoint.docx"))
print("Created quest-with-checkpoint.docx")
