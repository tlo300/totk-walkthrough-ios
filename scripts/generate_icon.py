"""
Generate iOS app icon PNGs from the SVG source.

Requires: cairosvg
Install:  pip install cairosvg

Usage:
    python scripts/generate_icon.py
"""

from pathlib import Path
import cairosvg

REPO_ROOT = Path(__file__).parent.parent
SVG_SOURCE = REPO_ROOT / "assets" / "icon_source.svg"
APPICONSET = REPO_ROOT / "app" / "Sources" / "Assets.xcassets" / "AppIcon.appiconset"

# Modern iOS only requires 1024x1024; Xcode generates the rest.
# Include the common sizes here for completeness / older toolchains.
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
svg_data = SVG_SOURCE.read_bytes()

for filename, size in SIZES:
    out_path = APPICONSET / filename
    cairosvg.svg2png(bytestring=svg_data, write_to=str(out_path), output_width=size, output_height=size)
    print(f"  wrote {filename} ({size}x{size})")

print("Done — icons written to", APPICONSET)
