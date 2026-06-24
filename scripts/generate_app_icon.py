#!/usr/bin/env python3
"""
Generates the Uniks app icon set for iOS and macOS.

Requires Pillow. Run from the project root:
    source .venv/bin/activate
    python3 scripts/generate_app_icon.py
"""

import json
import os
from pathlib import Path

from PIL import Image, ImageDraw

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ASSET_DIR = PROJECT_ROOT / "uniks" / "Assets.xcassets" / "AppIcon.appiconset"

# Background gradient colors (teal -> indigo)
TOP_COLOR = (45, 164, 178)
BOTTOM_COLOR = (67, 97, 238)
SYMBOL_COLOR = (255, 255, 255)

# macOS icon sizes: (filename, width_px, height_px)
MAC_SIZES = [
    ("mac_16x16.png", 16, 16),
    ("mac_16x16@2x.png", 32, 32),
    ("mac_32x32.png", 32, 32),
    ("mac_32x32@2x.png", 64, 64),
    ("mac_128x128.png", 128, 128),
    ("mac_128x128@2x.png", 256, 256),
    ("mac_256x256.png", 256, 256),
    ("mac_256x256@2x.png", 512, 512),
    ("mac_512x512.png", 512, 512),
    ("mac_512x512@2x.png", 1024, 1024),
]

# iOS App Store icon
IOS_SIZES = [
    ("ios_1024x1024.png", 1024, 1024),
]


def draw_rounded_gradient(size: int) -> Image.Image:
    """Draw a rounded-square gradient background."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    radius = size // 5
    for y in range(size):
        ratio = y / size
        r = int(TOP_COLOR[0] + (BOTTOM_COLOR[0] - TOP_COLOR[0]) * ratio)
        g = int(TOP_COLOR[1] + (BOTTOM_COLOR[1] - TOP_COLOR[1]) * ratio)
        b = int(TOP_COLOR[2] + (BOTTOM_COLOR[2] - TOP_COLOR[2]) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))

    # Re-draw with rounded mask
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)

    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(img, (0, 0), mask)
    return result


def draw_bolt(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a simple lightning-bolt symbol centered in the icon."""
    cx, cy = size // 2, size // 2
    s = size * 0.55
    # Bolt polygon points
    points = [
        (cx + s * 0.20, cy - s * 0.45),
        (cx - s * 0.15, cy + s * 0.05),
        (cx + s * 0.05, cy + s * 0.05),
        (cx - s * 0.20, cy + s * 0.45),
        (cx + s * 0.15, cy - s * 0.05),
        (cx - s * 0.05, cy - s * 0.05),
    ]
    draw.polygon(points, fill=SYMBOL_COLOR)


def generate_icon(width: int, height: int) -> Image.Image:
    """Generate the full icon at the requested pixel size."""
    size = min(width, height)
    img = draw_rounded_gradient(size)
    draw = ImageDraw.Draw(img)
    draw_bolt(draw, size)
    return img.resize((width, height), Image.Resampling.LANCZOS)


def generate_all() -> None:
    """Generate every icon size and update Contents.json."""
    ASSET_DIR.mkdir(parents=True, exist_ok=True)

    # Generate master 1024x1024 first, then downscale for crispness
    master = generate_icon(1024, 1024)

    generated = []
    for filename, width, height in MAC_SIZES + IOS_SIZES:
        icon = master.resize((width, height), Image.Resampling.LANCZOS)
        icon.save(ASSET_DIR / filename)
        generated.append(filename)
        print(f"Generated {filename}")

    # Update Contents.json
    contents_path = ASSET_DIR / "Contents.json"
    with contents_path.open("r", encoding="utf-8") as f:
        contents = json.load(f)

    for image in contents["images"]:
        idiom = image["idiom"]
        size = image["size"]
        scale = image.get("scale", "1x")

        if idiom == "universal":
            image["scale"] = "1x"
            image["filename"] = "ios_1024x1024.png"
        else:
            image["filename"] = f"mac_{size}.png" if scale == "1x" else f"mac_{size}@2x.png"

    with contents_path.open("w", encoding="utf-8") as f:
        json.dump(contents, f, indent=2)

    print(f"Updated {contents_path}")
    print(f"Generated {len(generated)} icon files.")


if __name__ == "__main__":
    generate_all()
