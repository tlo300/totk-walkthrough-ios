"""compress_images.py — Resize and recompress all bundled content images to reduce IPA size.

Usage:
    python -m scripts.compress_images [--content-dir PATH] [--max-width PX] [--quality Q]

Defaults: content-dir=app/Resources/Content, max-width=750, quality=60
"""
import argparse
import time
from pathlib import Path
from PIL import Image


def compress_image(path: Path, max_width: int, quality: int) -> tuple[int, int]:
    """Compress a single image. Returns (original_bytes, new_bytes)."""
    original_size = path.stat().st_size
    with Image.open(path) as img:
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
        w, h = img.size
        if w > max_width:
            new_h = int(h * max_width / w)
            img = img.resize((max_width, new_h), Image.LANCZOS)
        img.save(path, "JPEG", quality=quality, optimize=True)
    new_size = path.stat().st_size
    return original_size, new_size


def main() -> None:
    parser = argparse.ArgumentParser(description="Compress content images in-place.")
    parser.add_argument("--content-dir", default="app/Resources/Content")
    parser.add_argument("--max-width", type=int, default=750)
    parser.add_argument("--quality", type=int, default=60)
    args = parser.parse_args()

    content_dir = Path(args.content_dir)
    if not content_dir.exists():
        print(f"ERROR: content dir not found: {content_dir}")
        return

    image_paths = sorted(
        p for p in content_dir.rglob("*")
        if p.suffix.lower() in (".jpg", ".jpeg", ".png")
    )
    if not image_paths:
        print("No images found.")
        return

    print(f"Compressing {len(image_paths)} images (max_width={args.max_width}, quality={args.quality})...")
    total_before = total_after = 0
    for i, path in enumerate(image_paths, 1):
        before, after = compress_image(path, args.max_width, args.quality)
        total_before += before
        total_after += after
        if i % 100 == 0 or i == len(image_paths):
            print(f"  {i}/{len(image_paths)} done — saved {(total_before - total_after) / 1_048_576:.1f} MB so far")
        time.sleep(0)  # yield for keyboard interrupt

    saved = total_before - total_after
    print(
        f"\nDone. {total_before / 1_048_576:.1f} MB -> {total_after / 1_048_576:.1f} MB "
        f"(saved {saved / 1_048_576:.1f} MB, {100 * saved / total_before:.0f}% reduction)"
    )


if __name__ == "__main__":
    main()
