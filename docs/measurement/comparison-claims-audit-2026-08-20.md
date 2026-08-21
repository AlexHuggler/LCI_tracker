# Comparison claims audit — 20 August 2026

## Scope

This review covered the public US comparison hub, all four dedicated competitor pages, homepage competitor claims, visible and structured-data FAQs, the shared feature matrix, and the competitor records that feed those pages. PoolFlow product claims were checked against the current product inventory and US App Store listing. Competitor claims were checked only against first-party pricing, product, and help-center pages.

## Material corrections

| Vendor | Previous claim | Corrected treatment |
| --- | --- | --- |
| Skimmer | `$98 + $2/pool`, including a `$178` 40-pool estimate; no LSI or dosing | Getting Started begins at `$49/mo` for 49 locations. Scaling Up begins at `$98/mo`, includes 49 locations, then lists `$2` per additional location. Scaling Up and Enterprise include an Orenda-powered LSI and dosing calculator; route optimization is also plan-gated. |
| Jobber | Route optimization only on a `$169` Grow plan; no profitability tools | Route optimization is documented on Connect, Grow, and Plus. Job costing is documented on Grow and higher plans. Current pricing is shown as a starting price because commitments and promotions vary. |
| Pool Brain | `$40/mo`; no LSI, chemical-cost, inventory, or profit tools | No simple public starting price was found. Pool Brain documents Orenda LSI, automatic dosing, chemical costs, inventory, route profit, low-profit detection, billing, and a portal. |
| Pool Office Manager | `$30/mo per technician`; no profitability or inventory tools | The current page lists `$125/mo` for the first active user and `$25/mo` for each additional user. It documents a chemical calculator, inventory, customer-profitability reporting, invoicing, and QuickBooks Online sync. |
| PoolTrac | No chemistry, inventory, offline, portal, or invoicing | PoolTrac documents a chemical calculator, inventory monitoring, offline sync, a portal, invoicing, QuickBooks, and `$1` per visited location with a `$30` monthly minimum. |
| PoolCarePRO | `$59–$149/mo`; unsupported absence claims | Current published plans run from `$39.95/mo` for 3 users to `$99.95/mo` for 40 users. Only positively documented feature claims remain. |
| Pooltrackr | Misspelled brand; `$35/mo`; no chemistry or business tools | Brand spelling corrected. US price is listed as TBA. Public materials document water testing, recommendations, inventory, accounts, profitability, routing, and invoicing. |

## First-party sources

- Skimmer: <https://www.getskimmer.com/pricing> and <https://help.getskimmer.com/article/219-lsi-setup-and-activation-web>
- Jobber: <https://www.getjobber.com/pricing/> and <https://help.getjobber.com/en/articles/route-optimization-new-schedule/>
- Pool Brain: <https://help.poolbrain.com/en/>, <https://help.poolbrain.com/en/articles/6789830-chemical-settings-explained>, and <https://poolcompanysoftware.poolbrain.com/skimmer-vs-poolbrain>
- Pool Office Manager: <https://poolofficemanager.com/>
- PoolTrac: <https://www.pooltrac.com/pricing/>
- PoolCarePRO: <https://www.poolcarepro.com/pricing> and <https://www.poolcarepro.com/features>
- Pooltrackr: <https://pooltrackr.com/pricing/>
- PoolFlow US App Store listing: <https://apps.apple.com/us/app/poolflow-pool-service-pro/id6759516755>

## Ongoing controls

1. `_data/competitors.yml` is the single source of truth for competitor facts used by public pages.
2. Every competitor record must include a review date, at least one HTTPS first-party source, and a pricing summary.
3. Omitted feature data renders as “Not verified”; it cannot silently render as a red X.
4. Plan-specific or partial capabilities use a visible note in the matrix.
5. Unsourced pool-count price examples are prohibited by the validation script.
6. A correction that could affect a purchase decision is recorded in the public editorial policy.
7. Recheck all linked vendor pages before changing the `verified_at` date or publishing a new comparative claim.
