# Growth 90-day website implementation

## Changed

- `_includes/homepage.html`: made the five-pool free tier the primary US and AU entry point, added the assisted-setup offer using the verified `contact@poolflowapp.com` address, retained US$29.99 monthly / US$199.99 annual and A$49.99 monthly / A$299.99 annual pricing, and qualified introductory offers by Apple eligibility.
- `_includes/homepage.html`: clarified that the 30% chemical-cost flag is an account-review hint rather than a full net-profit calculation.
- `au/index.html`: aligned the Australian pricing FAQ with the conditional App Store offer language.
- `docs/aso/au/metadata.json`: prepared price-neutral English (Australia) promotional text and description without a fixed trial-duration promise or US pricing.
- `docs/aso/au/growth-90day-release-kit.md`: added the paste-ready metadata handoff and pre-submission checks.
- `docs/aso/au/scripts/validate-metadata.mjs` and its test: reject fixed trial durations and US prices in AU description copy.

## Checks

- `npm run build:css`
- `node --test docs/aso/au/tests/validate_metadata.test.mjs`
- `node docs/aso/au/scripts/validate-metadata.mjs`
- `bundle exec jekyll build` completed with a temporary Ruby 4 compatibility preload for Jekyll 3.9/Liquid 4 (`csv`, `bigdecimal`, and removed taint APIs); no compatibility files or dependency changes were added to the repository.
- `git diff --check`

## Limitations

- The assisted-setup action opens an email to the existing support address; there is no calendar or booking endpoint.
- Apple controls introductory-offer eligibility and purchase terms. The website and metadata do not guarantee a duration.
- This checkout contains source and release-kit changes only. Nothing was pushed, deployed or submitted to App Store Connect.
