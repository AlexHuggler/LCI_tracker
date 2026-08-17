# Subscription truth audit — release blocker

Date: 17 August 2026  
Status: incomplete; do not deploy website pricing changes or submit App Store metadata yet.

## Observed sources

| Source | What it currently communicates | Authority |
|---|---|---|
| Website global configuration | USD monthly and annual terms, an annual promotion and a 30-day trial | Marketing source; must follow the storefront |
| Local StoreKit test configuration | USD test prices and a one-month introductory period | Development fixture; not proof of live territory configuration |
| Public US App Store listing | Marketing copy and in-app-purchase display are not fully consistent | Public customer-facing evidence, but not the configuration source of record |
| Public AU App Store listing | Australian in-app-purchase display and listing copy are not fully consistent with the website | Public customer-facing evidence, but not the configuration source of record |
| App Store Connect subscriptions by territory | Not yet fully audited in this session | Required source of truth |

## Implemented safeguards

- Global and existing language pages use Apple's neutral App Store link.
- `/au/` alone uses the Australian storefront.
- Australian website and App Store draft copy avoid paid-price and trial-duration claims.
- Existing localized website FAQs now direct readers to the App Store for current local terms.
- AU structured data publishes no unverified paid AUD offer or rating.

## Required sign-off

For every active territory, export or record the monthly product, annual product, storefront display price, tax treatment where shown, subscription duration, introductory-offer eligibility/duration and promotion start/end state. Reconcile those values with RevenueCat, the submitted descriptions and the website market configuration. Record the approver and timestamp before deployment.
