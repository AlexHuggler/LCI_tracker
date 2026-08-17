# English (Australia) screenshot specification

These are local capture specifications, not uploads. Use only fictional data from the project’s AU demo fixture (`poolflow-demo-au-solo-mobile.csv`), with the app set to `en-AU` and metric units. Do not use production customers, real addresses, contact details, or an inferred subscription price.

## Device sets

| Set | Target canvas | Minimum set | Notes |
|---|---:|---:|---|
| iPhone 6.7-inch | 1290 × 2796 px portrait | 7 PNGs | Capture the real submitted build, no device frame or external overlay hiding UI. |
| iPad 13-inch | 2064 × 2752 px portrait | 7 PNGs | Capture the real submitted build in adaptive iPad layout. |

Re-check Apple’s current accepted display types and pixel sizes at upload time. This package intentionally does not assert that historical dimensions remain acceptable.

## Ordered messages and proof states

The first three messages below are locked to the approved implementation plan. They must appear exactly in this order. The remaining four cover the approved continuation themes.

| # | Exact message | Real UI proof | AU fictional data to show |
|---:|---|---|---|
| 1 | `Run every pool route in one app` | Daily route | Fictional Sydney service round, kilometres and Australian addresses. |
| 2 | `Log service in under 60 seconds` | Quick Log completion | Fictional pool, checklist, water readings and chemical doses; do not represent the caption as measured timing evidence. |
| 3 | `Balance water with instant LSI & dosing` | LSI and dosing result | Metric readings, °C and litre-based dose context from the real app UI. |
| 4 | `Optimise each service round` | Route optimisation preview | Bondi Route Pool / Manly Family Pool; route distance in km and any ETA clearly presented by the app. |
| 5 | `Track profit for every pool` | Profit analytics | A$ revenue, chemical spend and profit values; visibly labelled seeded/demo data if the UI supplies that label. |
| 6 | `Keep working through mobile blackspots` | Offline-capable service workflow | Real offline state or offline-safe service screen; do not simulate a connectivity indicator in post-production. |
| 7 | `Estimate pool volume in litres` | Volume calculator | Fictional metric dimensions and a litre result from the real calculator UI. |

Use Australian spelling in any external caption text. Screens may show A$ and litres only when the underlying real AU-seeded app UI renders them; never paint changed values onto an existing non-AU app capture.

The product owner explicitly approved retaining screenshot 2's “under 60 seconds” claim on 17 August 2026. This records the approved messaging decision; it is not presented as independent timing-test evidence.

## Capture gate and deterministic rendering

An existing deterministic compositor can resize and compose real simulator captures, but its checked-in source images were captured with a US marketing seed. It cannot truthfully change the on-screen customer data, measurement system or currency. Therefore no upload-ready AU images are generated in this package.

After a real AU capture pass, place only verified simulator PNGs in `marketing/au/source_screenshots/iphone/` and `marketing/au/source_screenshots/ipad/`, then run the renderer described in [../../../../marketing/au/README.md](../../../../marketing/au/README.md). The renderer fails closed if the source dimensions or any of the seven required filenames are absent.
