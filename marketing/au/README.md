# Local AU screenshot renderer

This is a local-only preparation tool. It does not call App Store Connect or submit screenshots.

Prerequisites:

1. Capture the real submitted build with `en-AU`, metric settings, and the fictional project AU demo data.
2. Review each capture against [../../docs/aso/au/screenshots/README.md](../../docs/aso/au/screenshots/README.md).
3. Put six reviewed iPhone PNGs under `source_screenshots/iphone/` and six reviewed iPad PNGs under `source_screenshots/ipad/`, using the filenames in `manifest.json`.

Then run:

```sh
python3 marketing/au/build_screenshot_sets.py
```

The output lives in `marketing/au/generated/` and is intentionally ignored by the package until source captures exist. The script only adds a small top caption band with the approved messages; it does not alter app UI or manufacture AU data.

The renderer requires Pillow (`PIL`), the same dependency used by the supplied July compositor. It exits without output if Pillow or reviewed source captures are unavailable.
