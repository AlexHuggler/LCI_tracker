---
title: PoolFlow Australia acquisition baseline
date: 2026-08-17
status: pre-release
---

# PoolFlow Australia acquisition baseline

This file is the pre-release measurement record for the additive Australian SEO, AI-search and App Store rollout. It is intentionally separate from production analytics and contains no credentials or customer data.

## Access and scope

- Website baseline date: 17 August 2026 (America/Chicago).
- App Store Connect app: PoolFlow (`6759516755`).
- Google Search Console: a URL-prefix property for `https://poolflowapp.com/` was created under `alexhuggler@gmail.com`. Google issued an HTML-tag verification token, which is staged in the site head and will be verified after GitHub Pages publishes it.
- App Store Connect acquisition metrics and RevenueCat subscription/customer metrics were filtered to Australia for the 90-day baseline below. The previously captured App Store Connect global metrics remain the non-AU guardrail.

## App Store Connect — 90-day global guardrail

Captured from App Analytics before changes. These are global aggregates, not Australian results.

| Metric | Baseline |
|---|---:|
| First-time downloads | 149 |
| Redownloads | 4 |
| Conversion rate (daily average) | 3.59% |
| Impressions | 6,150 |
| Product page views | 396 |
| Updates | 257 |
| Proceeds | US$50 |
| In-app purchases | 8 |
| Active plans | 5 |
| Monthly recurring revenue | US$26 |
| Net paid plans | -1 |
| Churned plans | 1 |

## RevenueCat — 90-day Australian baseline

Captured for 20 May–17 August 2026 with `Country = Australia`. RevenueCat measures app customers and subscription events; it does not replace App Store product-page impressions or views.

| Metric | Baseline |
|---|---:|
| New customers | 2 |
| New trials | 0 |
| New paid subscriptions | 0 |
| Recognised revenue | US$0 |

## App Store Connect — 90-day Australian baseline

Captured for 19 May–16 August 2026 with `Region = Australia`. App Store Connect reported no impression total for this slice (`-`), so do not infer a zero-impression baseline from the missing value.

| Metric | Baseline |
|---|---:|
| Impressions | Not reported (`-`) |
| Product-page views | 2 |
| First-time downloads | 2 |
| Conversion rate | 8% |

## Release gates

- [x] Record AU impressions, product-page views, first-time downloads and conversion for the 90-day pre-release window. Impressions were not reported for the selected slice and are recorded as unavailable, not zero.
- [x] Record non-AU/global App Store metrics for regression guardrails.
- [ ] Verify the staged Search Console token after GitHub Pages deploys, submit the sitemap, and begin collecting AU clicks, impressions, CTR, positions, queries and indexed pages. No historical Search Console data exists in this new property yet.
- [x] Verify the live US and Australian subscription display prices and the introductory-offer duration used by the public release scope.
- [x] Reconcile the website, live storefront purchase display, RevenueCat product configuration and AU metadata draft. The currently released AU description remains stale until the next App Store metadata submission; the website and new draft do not repeat those stale terms.
- [ ] Capture the 20-query test set below in each named engine from an Australian locale or clearly record the test locale.

## Search observation

In a qualitative Australian Google sample, PoolFlow did not surface for the generic terms `pool service app Australia`, `pool service software Australia`, `pool technician app Australia`, or `best pool service software Australia`. PoolFlow did surface for branded/site-specific searches, and its Australian App Store page was indexed. This is an observation, not a rank guarantee or volume estimate.

## Repeatable 20-query Australian test set

Use the exact strings below in Google Search, Google AI Mode, ChatGPT Search, Gemini and Perplexity. Record date, locale, signed-in state, PoolFlow mention, rank/placement, cited URL and factual errors.

1. pool service software Australia
2. pool service app Australia
3. pool technician app Australia
4. best pool service software Australia
5. pool maintenance business app Australia
6. pool service software for sole traders
7. simple pool service app Australia
8. pool software for one person
9. pool app without invoicing
10. pool route app for solo technician
11. affordable pool service app Australia
12. offline pool service app Australia
13. pool route optimisation Australia
14. pool service log app Australia
15. chemical cost tracking pool business
16. LSI calculator Australia
17. chemical dosing calculator litres
18. pool profitability calculator Australia
19. PoolFlow Australia price
20. pool software without fleet management

## Review cadence

Review at 2, 4, 8 and 12 weeks after each release phase. Compare AU non-brand discovery and conversion with the pre-change global guardrails. Treat rankings as measured outcomes. Pause isolated metadata tests if AU conversion materially declines; pause global snippet changes if comparable non-AU organic CTR declines while traffic mix is stable.
