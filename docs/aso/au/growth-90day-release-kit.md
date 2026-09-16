# PoolFlow English (Australia) App Store release kit

Use the checked-in values in [`metadata.json`](metadata.json) for the `en-AU` listing. The description and promotional text are ready to paste into App Store Connect after the current storefront terms are checked.

## Promotional text

> Built for solo Australian pool techs: offline routes, service logs, LSI dosing and per-pool profit—without fleet-software overhead. Free for 5 pools.

## Description

The complete description is the `description` field in [`metadata.json`](metadata.json). It:

- uses Australian spelling and field units;
- keeps the paid price out of mutable listing copy;
- states that up to five pools are free;
- makes any introductory offer conditional on Apple eligibility and the purchase screen;
- describes the 30% chemical-cost flag as an account-review hint rather than full net profit; and
- contains no fixed trial duration or US price.

The verified storefront prices used on the website are A$49.99 monthly and A$299.99 annually. Recheck them in the Australian App Store immediately before submission. Do not add a fixed trial duration unless the live purchase screen confirms that exact offer for the eligible account being used to verify it.

## Validation

```sh
node --test docs/aso/au/tests/validate_metadata.test.mjs
node docs/aso/au/scripts/validate-metadata.mjs
```
