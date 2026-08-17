# Release-notes localisation plan

## Ready-to-review maintenance release copy

These strings describe only stability and workflow polish. They do not introduce a price, trial, ranking or new-feature claim. Confirm the exact locale identifiers already enabled in App Store Connect before paste-in.

| Locale | Release notes |
|---|---|
| `en-US` | Stability fixes and workflow polish for route management, water chemistry, dosing, inventory, and profit tracking. |
| `en-AU` | Stability fixes and workflow polish for route management, water chemistry, dosing, inventory and profit tracking. |
| `es-MX` | Correcciones de estabilidad y mejoras en el flujo de trabajo para rutas, química del agua, dosificación, inventario y seguimiento de rentabilidad. |
| `es-ES` | Correcciones de estabilidad y mejoras del flujo de trabajo para rutas, química del agua, dosificación, inventario y seguimiento de la rentabilidad. |
| `fr-FR` | Correctifs de stabilité et améliorations du flux de travail pour les tournées, la chimie de l’eau, le dosage, le stock et le suivi de la rentabilité. |
| `de-DE` | Stabilitätskorrekturen und Verbesserungen der Arbeitsabläufe für Routen, Wasserchemie, Dosierung, Bestand und Rentabilitätsanalyse. |
| `pt-BR` | Correções de estabilidade e melhorias no fluxo de trabalho de rotas, química da água, dosagem, estoque e acompanhamento de rentabilidade. |
| `pt-PT` | Correções de estabilidade e melhorias no fluxo de trabalho de rotas, química da água, dosagem, inventário e acompanhamento da rentabilidade. |
| `nl-NL` | Stabiliteitsverbeteringen en verfijningen voor routes, waterchemie, dosering, voorraad en winstregistratie. |

## English (Australia)

Use the `whatsNew` value in [metadata.json](metadata.json) for a maintenance release with no AU-specific feature claim. For feature releases, localise spelling and measurement language before submission:

- `optimise`, `organisation`, `licence` (noun), `litres`, `metres`
- A$ only when the value is demonstrably the Australia storefront price
- Do not claim a service time, savings amount, or availability that is not demonstrated in the submitted build

## Portuguese: pt-PT is not pt-BR

The current product/localisation evidence supports `pt-BR`, not a complete `pt-PT` app UI. The maintenance string above is deliberately separated and must receive a European Portuguese review before a Portuguese (Portugal) storefront is enabled; do not clone the Brazilian string.

| Locale | Current action | Required wording / review |
|---|---|---|
| `pt-BR` | Maintain a Brazilian Portuguese release-note localisation. | Use Brazilian vocabulary and punctuation; validate against the supported in-app `pt-BR` locale. |
| `pt-PT` | Do not create from the Brazilian string by copy/paste. | Commission a European Portuguese localisation, check terminology and subscription wording, then capture and review a pt-PT UI before adding the storefront locale. |

This avoids presenting Brazil-specific terminology or R$ pricing to Portugal. Storefront price text is never copied between these locales; App Store Connect must supply the relevant local price.

## Release checklist

1. Confirm the build supports every claimed feature and selected UI locale.
2. Put substantive user-facing changes first; do not use release notes for keyword stuffing.
3. Review AU spelling, metric examples and currency marker.
4. Keep `pt-BR` and `pt-PT` separate records, reviewers and screenshots.
5. Submit only after localisation and screenshot review in App Store Connect; this package performs no submission.
