# PoolFlow App Store optimisation — English (Australia)

Status: local working package only. Nothing in this directory is an App Store Connect submission request or an instruction to change the global app name.

## Approved listing fields

| Field | Copy / value | Check |
|---|---|---|
| Locale | `en-AU` | required |
| App name | `PoolFlow: Pool Service Pro` | 26 / 30 characters; preserve the existing global title |
| Subtitle | `Routes, Logs & Water Testing` | 28 / 30 characters |
| Promotional text | `Built for solo Australian pool techs: offline routes, service logs, LSI dosing and per-pool profit—without fleet-software overhead. Free for 5 pools.` | exact approved, price-free copy; 149 / 170 characters |
| Keywords | `maintenance,cleaning,technician,software,planner,LSI,calculator,dosing,offline` | 78 / 100 UTF-8 bytes; preserves the approved starting field and avoids exact title/subtitle duplication |
| Description / What’s New | [metadata.json](metadata.json) | validated locally |

The promotional text is deliberately price-free: the approved plan establishes free use for up to five pools, while actual paid terms must be the Australia storefront’s A$ product price at the time of submission. Do not place a converted, inferred, or US price in metadata.

## Validation

Run from this site checkout:

```sh
node --test docs/aso/au/tests/validate_metadata.test.mjs
node docs/aso/au/scripts/validate-metadata.mjs
```

The validator enforces required fields, App Store character ceilings, the 100-byte UTF-8 keyword ceiling, exact approved promotional text, no exact title/subtitle keyword duplication, and AU description markers (`optimisation`, `litres`, and `A$`).

## Evidence and scope

- The app contains an English (Australia) locale and an AU mobile-route demo dataset with fictional NSW, QLD, VIC and WA customers, metric volumes, and A$ fees.
- The precise promotional text is retained from the approved implementation plan; it carries no paid-price or trial-duration claim.
- No public page, website template, global title, app source, App Store Connect record, product, screenshot set, or release was changed.

See [screenshots/README.md](screenshots/README.md) for capture and rendering requirements and [release-notes-localization-plan.md](release-notes-localization-plan.md) for locale handling.
