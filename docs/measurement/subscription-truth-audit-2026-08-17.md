# Subscription truth audit — release blocker

Date: 17 August 2026  
Status: verified for the public website release scope; AU App Store metadata remains a separate next-version submission.

## Observed sources

| Source | What it currently communicates | Authority |
|---|---|---|
| Website global configuration | US$29.99 monthly, US$199.99 early-access annual and a 30-day trial | Matches the live US purchase display and observed live trial behaviour |
| Local StoreKit test configuration | USD test prices and a one-month introductory period | Development fixture; not proof of live territory configuration |
| Public US App Store purchase display | PoolFlow Premium Monthly US$29.99; Annual US$199.99 | Live Apple storefront, checked 17 August 2026 |
| Public AU App Store purchase display | PoolFlow Premium Monthly A$49.99; Annual A$299.99 | Live Apple storefront, checked 17 August 2026 |
| RevenueCat product catalog | Active App Store products `Pool_01` monthly and `Pool_02` annual in the default offering | Live product configuration, checked 17 August 2026 |
| RevenueCat production events | Monthly and annual trials span approximately one month before conversion/expiry | Live event evidence consistent with the 30-day configuration |
| Released AU App Store description | Still says `$29.99/$299.99` and a one-week trial | Stale marketing copy; replace with the price-free AU draft in the next version |
| App Store Connect subscription screen | Authenticated successfully but its subscription endpoint repeatedly returned Apple’s “something went wrong” error | Apple UI availability issue; cross-checked with the live storefront and RevenueCat |

## Implemented safeguards

- Global and existing language pages use Apple's neutral App Store link.
- `/au/` alone uses the Australian storefront.
- Australian website and App Store draft copy avoid paid-price and trial-duration claims.
- Existing localized website FAQs now direct readers to the App Store for current local terms.
- AU structured data publishes no unverified paid AUD offer or rating.

## Required sign-off

For future country pages that publish a numeric price, record that storefront’s live monthly and annual display prices and tax presentation before release. Existing global/localized pages use Apple’s storefront-localised link, while `/au/` deliberately remains price-neutral. Product owner Alex Huggler approved keeping the “Log service in under 60 seconds” marketing claim on 17 August 2026.
