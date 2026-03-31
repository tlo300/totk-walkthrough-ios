"""Downloads shrine/tower coords from alshival/totk-map and writes map-locations.json."""
import csv
import json
import re
import sys
import time
from pathlib import Path

import requests

SHRINES_CSV_URL = (
    "https://raw.githubusercontent.com/alshival/totk-map/main/map_data/shrines.csv"
)
TOWERS_CSV_URL = (
    "https://raw.githubusercontent.com/alshival/totk-map/main/map_data/skyview_towers.csv"
)
MAP_IMAGE_URL = (
    "https://raw.githubusercontent.com/alshival/totk-map/main/map_data/base_map.png"
)

CONTENT_DIR = Path(__file__).parent.parent / "app" / "Resources" / "Content"
SHRINES_INDEX = CONTENT_DIR / "shrines" / "index.json"
OUT_JSON = CONTENT_DIR / "map-locations.json"
OUT_IMAGE = CONTENT_DIR / "map-base.png"

DELAY = 1.5


def slugify(name: str) -> str:
    name = name.lower()
    name = re.sub(r"[^a-z0-9]+", "-", name)
    name = re.sub(r"-guide$", "", name)
    return name.strip("-")


def layer_from_str(s: str) -> str:
    s = s.strip().lower()
    if s == "sky":
        return "sky"
    if s in ("depths", "depth"):
        return "depths"
    return "surface"


def fetch_csv(url: str) -> list[dict]:
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    time.sleep(DELAY)
    return list(csv.DictReader(resp.text.splitlines()))


def main() -> None:
    CONTENT_DIR.mkdir(parents=True, exist_ok=True)
    index_data = json.loads(SHRINES_INDEX.read_text(encoding="utf-8"))
    slug_set = {q["slug"] for q in index_data["quests"]}

    pins: list[dict] = []

    print("Fetching shrine coordinates...")
    shrine_rows = fetch_csv(SHRINES_CSV_URL)
    unmatched: list[str] = []
    for row in shrine_rows:
        name = row["Shrine Name"].strip()
        slug = slugify(name)
        if slug not in slug_set:
            unmatched.append(name)
            continue
        pins.append(
            {
                "slug": slug,
                "type": "shrine",
                "layer": layer_from_str(row["Map Layer"]),
                "x": float(row["X"]),
                "y": float(row["Y"]),
            }
        )

    if unmatched:
        print(f"WARNING: {len(unmatched)} unmatched shrines:", file=sys.stderr)
        for name in unmatched:
            print(f"  {name!r} -> {slugify(name)!r}", file=sys.stderr)

    print("Fetching tower coordinates...")
    tower_rows = fetch_csv(TOWERS_CSV_URL)
    for row in tower_rows:
        name = (row.get("Tower Name") or row.get("Name") or row.get("tower") or "").strip()
        if not name:
            continue
        slug = slugify(name)
        layer_raw = row.get("Map Layer") or row.get("Layer") or "surface"
        x_raw = row.get("X") or row.get("x") or ""
        y_raw = row.get("Y") or row.get("y") or ""
        if not x_raw or not y_raw:
            print(f"WARNING: skipping tower {name!r} — missing coordinates", file=sys.stderr)
            continue
        pins.append(
            {
                "slug": slug,
                "type": "tower",
                "layer": layer_from_str(layer_raw),
                "x": float(x_raw),
                "y": float(y_raw),
                "name": name,
            }
        )

    print("Downloading map image...")
    resp = requests.get(MAP_IMAGE_URL, timeout=60)
    resp.raise_for_status()
    OUT_IMAGE.write_bytes(resp.content)
    print(f"Saved map image: {OUT_IMAGE}")

    OUT_JSON.write_text(json.dumps(pins, indent=2), encoding="utf-8")
    shrine_count = sum(1 for p in pins if p["type"] == "shrine")
    tower_count = sum(1 for p in pins if p["type"] == "tower")
    print(f"Wrote {len(pins)} pins ({shrine_count} shrines, {tower_count} towers) to {OUT_JSON}")


if __name__ == "__main__":
    main()
