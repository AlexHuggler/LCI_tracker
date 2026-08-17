#!/usr/bin/env python3
"""Build local App Store screenshot layouts from reviewed AU simulator captures."""
from pathlib import Path
import json
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ModuleNotFoundError:
    print(
        "AU screenshot renderer stopped: Pillow is required; install it in a local Python environment before rendering.",
        file=sys.stderr,
    )
    raise SystemExit(2)

ROOT = Path(__file__).resolve().parent
MANIFEST = json.loads((ROOT / "manifest.json").read_text())
FONT = "/System/Library/Fonts/SFNS.ttf"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def render_set(device, config):
    width, height = config["canvas"]
    source_dir = ROOT / "source_screenshots" / device
    output_dir = ROOT / "generated" / device
    output_dir.mkdir(parents=True, exist_ok=True)
    caption_height = round(height * 0.17)
    font = ImageFont.truetype(FONT, round(width * 0.052))

    for item in MANIFEST["items"]:
        source = source_dir / item["file"]
        require(source.exists(), f"Missing reviewed {device} capture: {source}")
        with Image.open(source) as image:
            require(image.size == (width, height),
                    f"{source} is {image.size}; expected {(width, height)}")
            canvas = image.convert("RGB")

        # Caption is external marketing text, never an edit of app values or UI.
        overlay = Image.new("RGBA", (width, caption_height), (5, 23, 42, 238))
        draw = ImageDraw.Draw(overlay)
        text = item["message"]
        bounds = draw.textbbox((0, 0), text, font=font)
        text_x = (width - (bounds[2] - bounds[0])) // 2
        text_y = (caption_height - (bounds[3] - bounds[1])) // 2 - bounds[1]
        draw.text((text_x, text_y), text, font=font, fill="white")
        canvas.paste(overlay, (0, 0), overlay)
        canvas.save(output_dir / item["file"], "PNG", optimize=True)


def main():
    try:
        for device, config in MANIFEST["sets"].items():
            render_set(device, config)
    except (OSError, ValueError) as error:
        print(f"AU screenshot renderer stopped: {error}", file=sys.stderr)
        return 1
    print("Rendered reviewed AU screenshot sets to marketing/au/generated/.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
