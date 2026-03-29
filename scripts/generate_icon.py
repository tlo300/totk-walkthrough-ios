"""
Generate iOS app icon PNGs from the SVG source.

Requires: svglib reportlab Pillow
Install:  pip install svglib reportlab Pillow

Usage:
    python scripts/generate_icon.py
"""

from pathlib import Path
from io import BytesIO
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPM
from PIL import Image

REPO_ROOT = Path(__file__).parent.parent
SVG_SOURCE = REPO_ROOT / "assets" / "icon_source.svg"
APPICONSET = REPO_ROOT / "app" / "Sources" / "Assets.xcassets" / "AppIcon.appiconset"

SIZES = [
    ("Icon-20@2x.png", 40),
    ("Icon-20@3x.png", 60),
    ("Icon-29@2x.png", 58),
    ("Icon-29@3x.png", 87),
    ("Icon-40@2x.png", 80),
    ("Icon-40@3x.png", 120),
    ("Icon-60@2x.png", 120),
    ("Icon-60@3x.png", 180),
    ("Icon-1024.png", 1024),
]

APPICONSET.mkdir(parents=True, exist_ok=True)

drawing = svg2rlg(str(SVG_SOURCE))
# Render at full SVG size (1024x1024) first, then downsample with Pillow for quality
buf = BytesIO()
renderPM.drawToFile(drawing, buf, fmt="PNG", dpi=72)
buf.seek(0)
source_img = Image.open(buf).convert("RGBA")

for filename, size in SIZES:
    out_path = APPICONSET / filename
    resized = source_img.resize((size, size), Image.LANCZOS)
    resized.save(str(out_path), "PNG")
    print(f"  wrote {filename} ({size}x{size})")

print("Done — icons written to", APPICONSET)
