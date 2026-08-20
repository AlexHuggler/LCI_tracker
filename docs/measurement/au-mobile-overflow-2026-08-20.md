# Australian mobile overflow verification

Date: 20 August 2026
Build: local production Jekyll output from `codex/au-market-parity`

## Method

The built site was served locally and inspected in Google Chrome. At each viewport, the test compared the document and body `scrollWidth` with the document `clientWidth`; any positive difference failed the case.

Viewports: 320 × 900, 360 × 900, 390 × 900 and 768 × 900 pixels.

Pages:

- `/`
- `/au/`
- `/au/tools/`
- `/au/lsi-calculator/`
- `/au/chemical-dosing-calculator/`
- `/au/pool-volume-calculator/`
- `/au/salt-calculator/`
- `/au/free-chlorine-calculator/`
- `/au/pump-run-time-calculator/`
- `/au/compare/`
- `/au/support/`
- `/au/offline-pool-service-app/`
- `/au/pool-route-optimisation/`
- `/au/pool-chemical-dosing-litres/`
- `/au/pool-profitability-tracking/`
- `/au/pool-service-software-for-sole-traders/`

## Result

All 64 page/viewport cases reported zero horizontal overflow.

The same browser run also confirmed metric-first runtime output on the Australian dosing, salt, pump run-time, volume and LSI calculators. The Australian dosing calculator rendered no generic dollar estimate.
