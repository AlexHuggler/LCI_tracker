# PoolFlow — Functional Scope

> **Document:** 04_Functional_Scope
> **Version:** 2.1
> **Last Updated:** 2026-02-25
> **Related Docs:** [01_App_Blueprint](01_App_Blueprint.md) | [02_Product_Strategy](02_Product_Strategy.md) | [03_Feature_Inventory](03_Feature_Inventory.md) | [05_Customer_Journeys](05_Customer_Journeys.md)

This document details every business rule, formula, constant, threshold, and algorithm implemented in the PoolFlow codebase. All values are extracted directly from source code and verified against unit tests.

---

## 1. Water Chemistry Engine

### 1.1 LSI (Langelier Saturation Index) Calculation

**Source:** `Engine/LSICalculator.swift`

#### Formula

```
LSI = pH + TF + CF + AF - TDS_Constant
```

Where:
- **pH** = Measured pH of the water (direct input, no transformation)
- **TF** = Temperature Factor (linearly interpolated from lookup table)
- **CF** = Calcium Hardness Factor (linearly interpolated from lookup table)
- **AF** = Alkalinity Factor (linearly interpolated from lookup table, using **adjusted** alkalinity)
- **TDS_Constant** = Total Dissolved Solids correction factor (linearly interpolated from lookup table; default 12.10 for TDS = 1000 ppm)

#### CYA Alkalinity Adjustment

Before the alkalinity factor lookup, cyanuric acid is subtracted from total alkalinity:

```
adjustedAlkalinity = max(0, totalAlkalinity - (cyanuricAcid / 3.0))
```

This accounts for CYA's buffering effect which causes raw Total Alkalinity readings to overstate the water's true carbonate alkalinity. The adjusted value enters the AF lookup table.

**Source:** `LSICalculator.calculate()` line: `let adjustedAlk = max(0, totalAlkalinity - (cyanuricAcid / 3.0))`

#### Linear Interpolation

All factor lookups use linear interpolation between sorted table points. For a value `v` between points `(v1, f1)` and `(v2, f2)`:

```
factor = f1 + (f2 - f1) * (v - v1) / (v2 - v1)
```

Boundary behavior:
- Values below the first table entry return the first factor
- Values above the last table entry return the last factor

**Source:** `LSICalculator.interpolate(value:table:)` method

#### Factor Lookup Tables

**Temperature Factor (TF):**

| Temp (F) | Factor |
|----------|--------|
| 32 | 0.0 |
| 37 | 0.1 |
| 46 | 0.2 |
| 53 | 0.3 |
| 60 | 0.4 |
| 66 | 0.5 |
| 76 | 0.6 |
| 84 | 0.7 |
| 94 | 0.8 |
| 105 | 0.9 |

**Calcium Hardness Factor (CF):**

| Ca (ppm) | Factor |
|----------|--------|
| 5 | 0.3 |
| 25 | 1.0 |
| 50 | 1.3 |
| 75 | 1.5 |
| 100 | 1.6 |
| 150 | 1.8 |
| 200 | 1.9 |
| 250 | 2.0 |
| 300 | 2.1 |
| 400 | 2.2 |
| 500 | 2.3 |
| 600 | 2.35 |
| 800 | 2.5 |
| 1000 | 2.6 |

**Alkalinity Factor (AF) -- uses Adjusted Alkalinity:**

| Alk (ppm) | Factor |
|-----------|--------|
| 5 | 0.7 |
| 25 | 1.4 |
| 50 | 1.7 |
| 75 | 1.9 |
| 100 | 2.0 |
| 125 | 2.1 |
| 150 | 2.2 |
| 200 | 2.3 |
| 250 | 2.4 |
| 300 | 2.5 |
| 400 | 2.6 |
| 500 | 2.7 |
| 600 | 2.8 |
| 800 | 2.9 |
| 1000 | 3.0 |

**TDS Correction Constant:**

The standard LSI formula uses 12.1 for TDS ~1000 ppm. This table provides refinement for other TDS levels.

| TDS (ppm) | Constant |
|-----------|----------|
| 0 | 12.27 |
| 400 | 12.23 |
| 800 | 12.15 |
| 1000 | 12.10 |
| 1200 | 12.05 |
| 1500 | 12.00 |
| 2000 | 11.92 |
| 3000 | 11.82 |
| 4000 | 11.74 |
| 5000 | 11.68 |

#### Classification Thresholds

| LSI Range | Classification | Emoji | Description |
|-----------|---------------|-------|-------------|
| < -0.3 | **Corrosive** | Warning | Water is aggressive -- dissolves plaster, corrodes equipment, etches surfaces |
| -0.3 to +0.3 | **Balanced** | Check | Water is balanced -- no significant scaling or corrosion tendency |
| > +0.3 | **Scale-Forming** | Caution | Water is scale-forming -- calcium deposits, cloudy water, clogged heaters |

**Source:** `LSIResult.status` computed property and `WaterCondition.from(lsiValue:)` static method

#### LSIResult Output Struct

The calculator returns an `LSIResult` struct containing:

| Field | Type | Description |
|-------|------|-------------|
| `lsiValue` | Double | The computed LSI number |
| `temperatureFactor` | Double | TF component |
| `calciumFactor` | Double | CF component |
| `alkalinityFactor` | Double | AF component |
| `tdsFactor` | Double | TDS constant used |
| `pH` | Double | Input pH echoed back |
| `adjustedAlkalinity` | Double | TA after CYA correction |
| `cyanuricAcid` | Double | Input CYA echoed back |
| `status` | WaterCondition | Computed classification (corrosive/balanced/scaleForming) |
| `deviationFromEquilibrium` | Double | Distance from 0.0 (equal to lsiValue) |

#### Pool-Level LSI Caching

Each Pool model has a `cachedLSI` field that is recalculated via `pool.recalculateLSI()` whenever water chemistry readings change. This avoids recalculating LSI in list views.

**Source:** `Pool.recalculateLSI()` calls `LSICalculator.calculate()` and stores the result in `cachedLSI`.

### 1.2 Dosing Engine

**Source:** `Engine/DosingEngine.swift`

#### Dosing Constants (Per 10,000 Gallons)

| Constant Name | Value | Chemical | Effect |
|---------------|-------|----------|--------|
| `muriaticAcidOzPer10kGalPerPointTwoPH` | **26.0 oz** | Muriatic Acid (31.45%) | Lowers pH by 0.2 |
| `sodaAshOzPer10kGalPerPointTwoPH` | **6.0 oz** | Soda Ash (Sodium Carbonate, 100%) | Raises pH by 0.2 |
| `sodiumBicarbOzPer10kGalPer10ppmTA` | **24.0 oz** | Sodium Bicarbonate (Baking Soda) | Raises TA by 10 ppm |
| `calciumChlorideOzPer10kGalPer10ppmCH` | **20.0 oz** | Calcium Chloride (Hardness Up, 77%) | Raises CH by 10 ppm |

#### Volume Scaling

All constants are defined per 10,000 gallons. For a pool with volume `V`:

```
volumeFactor = V / 10,000
actual_dose = base_dose * volumeFactor
```

All computed doses are rounded **up** to the nearest 1 oz using ceiling rounding:

```swift
static func ceilToNearest(_ value: Double, nearest: Double) -> Double {
    (value / nearest).rounded(.up) * nearest
}
```

#### Dosing Strategy: Corrosive Water (LSI < -0.3)

When `deviation < -0.3`, recommendations are generated in priority order (pH first, as it is fastest acting and most impactful):

**Step 1: Raise pH** (if `currentPH < 7.4`)
- Chemical: Soda Ash (Sodium Carbonate)
- Target: pH 7.4
- Formula: `ozNeeded = ((7.4 - currentPH) / 0.2) * 6.0 * volumeFactor`
- Rounded up to nearest 1 oz

**Step 2: Raise Total Alkalinity** (if `currentTA < 80`)
- Chemical: Sodium Bicarbonate (Baking Soda)
- Target: 80 ppm
- Formula: `ozNeeded = ((80 - currentTA) / 10.0) * 24.0 * volumeFactor`
- Rounded up to nearest 1 oz

**Step 3: Raise Calcium Hardness** (if `currentCH < 200`)
- Chemical: Calcium Chloride (Hardness Up)
- Target: 200 ppm
- Formula: `ozNeeded = ((200 - currentCH) / 10.0) * 20.0 * volumeFactor`
- Rounded up to nearest 1 oz

#### Dosing Strategy: Scale-Forming Water (LSI > +0.3)

When `deviation > 0.3`, recommendations are generated in priority order:

**Step 1: Lower pH** (if `currentPH > 7.6`)
- Chemical: Muriatic Acid (31.45%)
- Target: pH 7.6
- Formula: `ozNeeded = ((currentPH - 7.6) / 0.2) * 26.0 * volumeFactor`
- Rounded up to nearest 1 oz

**Step 2: Lower Total Alkalinity** (if `currentTA > 120` AND `currentPH <= 7.6`)
- Chemical: Muriatic Acid (31.45%)
- Target: 120 ppm
- Formula: `ozNeeded = ((currentTA - 120) / 10.0) * 26.0 * 0.5 * volumeFactor`
- Note: Uses half the normal acid dose because acid affects both pH and TA
- Instruction includes note: "then aerate to restore pH"
- Only triggered when pH is already at or below target (to avoid over-acidifying)

**Step 3: High Calcium Hardness** (if `currentCH > 400`)
- Chemical: None (partial drain and refill)
- Calcium cannot be chemically removed from pool water
- Recommendation: "Calcium at {currentCH} ppm is too high for chemical correction. Recommend partial drain and fresh water refill to dilute below 400 ppm."

#### Balanced Water (LSI -0.3 to +0.3)

Returns a single recommendation with:
- `chemicalName: "None"`
- `chemicalType: .none`
- `instructionData: .balanced`
- Message: "Water is balanced. No chemical adjustment needed."

#### Zero Volume Guard

If `poolVolumeGallons <= 0`, returns a `.volumeRequired` recommendation:
- Message: "Pool volume is required before dosing can be calculated."

#### Fallback Nudge Logic

If the LSI is out of balance but no specific parameter triggers a recommendation (e.g., pH is within thresholds but LSI is still off), the engine provides a general pH nudge:

- **Negative LSI (< 0):** 3.0 oz Soda Ash * volumeFactor, rounded up
- **Positive LSI (> 0):** 8.0 oz Muriatic Acid * volumeFactor, rounded up
- Instruction: "Add {qty} of {chemical} to nudge pH {direction} slightly. Retest in 4 hours."

#### Cost Calculation

For each recommendation:
```
estimatedCost = quantityOz * costPerOz
```

**Cost Source Priority:**
1. Matched `ChemicalInventory` item by `ChemicalType` (first match per type)
2. Industry default costs (fallback):

| ChemicalType | Default $/oz |
|-------------|-------------|
| `.acid` | $0.05 |
| `.base` | $0.09 |
| `.calcium` | $0.07 |
| `.alkalinity` | $0.04 |
| `.chlorine` | $0.02 |
| `.stabilizer` | $0.12 |

**Source:** `DosingEngine.CostLookup.defaults` dictionary

#### Quantity Formatting (Imperial)

All internal calculations use ounces. Display conversion:

| Range | Display Format |
|-------|---------------|
| `oz <= 0` | "--" (em dash) |
| `oz < 16` | `"{oz} oz"` |
| `16 <= oz < 128` | `"{lbs} lb(s) {remainder} oz"` |
| `oz >= 128` | `"{gallons:.1f} gal"` |

**Source:** `DosingEngine.formatQuantity(_:)` and `UnitManager.formatImperial(_:)`

#### Metric Formatting

When UnitSystem is metric, chemicals are classified as dry or liquid:

**Dry Chemicals** (`.base`, `.alkalinity`, `.calcium`, `.stabilizer`): displayed in grams/kilograms
- `oz * 28.3495 = grams`
- If grams >= 1000: show as `"{kg:.1f} kg"`
- If grams < 1000: round to nearest 10g, show as `"{g} g"`

**Liquid Chemicals** (`.acid`, `.chlorine`): displayed in milliliters/liters
- `oz * 29.5735 = mL`
- If mL >= 1000: show as `"{L:.1f} L"`
- If mL < 1000: round to nearest 10mL, show as `"{mL} mL"`

**Source:** `Engine/DosingFormatter.swift`

### 1.3 Chemical Readings

#### Tracked Parameters

| Parameter | Stored On | Unit | Default Value |
|-----------|-----------|------|---------------|
| pH | Pool, ServiceEvent | unitless | 7.4 |
| Water Temperature | Pool, ServiceEvent | Fahrenheit (internal) | 78.0 |
| Calcium Hardness | Pool, ServiceEvent | ppm | 250.0 |
| Total Alkalinity | Pool, ServiceEvent | ppm | 100.0 |
| Total Dissolved Solids | Pool | ppm | 1000.0 |
| Cyanuric Acid (CYA) | Pool, ServiceEvent | ppm | 30.0 |

**Source:** `Models/WaterChemistryDefaults.swift`

#### Region-Aware Defaults

Chemistry constants (pH, CH, TA, TDS, CYA) are universal. Volume and temperature vary by region:

| Region | Pool Volume (gal) | Water Temp (F) |
|--------|------------------|----------------|
| US, CA | 15,000 | 78 |
| GB, DE | 13,209 (50,000 L) | 77 |
| AU, FR | 13,209 (50,000 L) | 79 |
| ES, BR | 13,209 (50,000 L) | 82 |
| All others | 13,209 (50,000 L) | 79 |

**Source:** `WaterChemistryDefaults.defaults(for:)` method

#### Latest Readings Resolution

When computing dosing or displaying chemistry, the system prefers the most recent `ServiceEvent` readings over pool-level defaults:

```swift
func latestReadings() -> WaterReadings {
    if let lastEvent = serviceEvents.max(by: { $0.timestamp < $1.timestamp }) {
        return WaterReadings(from: lastEvent)
    }
    return WaterReadings(from: poolDefaults)
}
```

**Source:** `Pool.latestReadings()` method

#### Historical Storage

Each `ServiceEvent` captures a snapshot of water chemistry at time of service:
- `waterTempF`, `pH`, `calciumHardness`, `totalAlkalinity`, `cyanuricAcid`
- `lsiValue` (computed at save time)
- `totalChemicalCost` (sum of all `ChemicalDose.cost` values)
- `timestamp` (automatically set to `Date()` at creation)
- `techNotes` (freeform text)
- `photoData` (JPEG, stored with `@Attribute(.externalStorage)`)
- `chemicalDoses` (cascade-deleted `[ChemicalDose]` relationship)

---

## 2. Route Optimization

**Source:** `ViewModels/RouteOptimizationEngine.swift`

### 2.1 Algorithm

#### Phase 1: Nearest-Neighbor Seeding

1. Start with the first pool in the current route order (sorted by `routeOrder`)
2. From the current position, evaluate all unvisited pools using `legScore()`
3. Select the pool with the lowest score and append it to the route
4. Repeat until all resolvable pools are placed

The starting point is always the first pool in the existing `routeOrder`.

#### Phase 2: 2-Opt Improvement

1. For each pair of edges `(i, k)` in the route where `1 <= i < k < count-1`:
   - Calculate the cost delta of reversing the segment between `i` and `k`
   - If `delta < -0.01` (meaningful improvement), apply the reversal
2. Maximum **2 passes** (`maxPasses = 2`) over the route for performance
3. Stop early if a pass produces no improvement (`madeImprovement = false`)

**Source:** `twoOptImprove(route:objective:originalIndex:)` method

#### Minimum Pool Requirement

- Optimization requires **3 or more** pools with valid coordinates
- If fewer than 3 resolvable pools, the current order is returned unchanged
- Valid coordinate: `!(pool.latitude == 0.0 && pool.longitude == 0.0)`

#### Unresolved Pools

Pools without coordinates (lat=0, lon=0) are excluded from optimization but maintain their relative positions in the merged result via `mergeOptimizedIDs()`.

### 2.2 Route Execution

#### Optimization Objectives

| Objective | `legScore()` Calculation |
|-----------|--------------------------|
| `minDriveTime` | `estimate.minutes` (travel time only) |
| `minDriveDistance` | `estimate.distanceMiles` (distance only) |
| `balanced` | `estimate.minutes + abs(targetIndex - expectedPosition) * 0.6` (time + displacement penalty) |

The `balanced` mode adds a displacement penalty of **0.6 minutes per position displaced** from the original order. This preserves the tech's existing familiarity with the route while still optimizing.

**Source:** `legScore(from:to:objective:expectedPosition:originalIndex:)` method

#### Travel Time Estimation

**Source:** `ViewModels/TravelTimeEstimator.swift`

**Primary: MapKit ETA** (`HybridTravelTimeEstimator`)
- Uses `MKDirections` API for real driving time between coordinate pairs
- Transport type: `.automobile`
- Minimum: `max(1, mapKitMinutes)` (at least 1 minute)
- Results cached in-memory per session (`actor`-isolated `[String: RouteLegEstimate]`)
- Cache key format: `"{lat},{lon}->{lat},{lon}"`

**Fallback: Haversine Approximation**
- Triggered when MapKit ETA is unavailable (offline, timeout, API error)
- Distance: Haversine great-circle formula with Earth radius = **3,958.8 miles**
- Assumed average driving speed: **28 mph**
- Per-leg overhead: **1.5 minutes** (parking, walking to backyard, etc.)
- Formula: `minutes = max(1, (distanceMiles / 28.0) * 60.0 + 1.5)`

**Source:** `HybridTravelTimeEstimator.approximateMinutes(forDistanceMiles:)` method

#### Navigation Integration

- Pool ordering is persisted via `routeOrder` field on each Pool model
- Route is reorderable via drag-and-drop in `PoolListView`
- `PoolListViewModel.movePool(from:to:in:)` updates `routeOrder` for all affected pools

#### Completion Tracking

- Route completion is tracked per-day via `ServiceEvent` timestamps
- When all pools for the current day have a ServiceEvent logged today, the route is considered complete
- Route completion triggers:
  - `hasCompletedRouteOnce = true` (if `totalDayPools >= 3`)
  - Notification prompt eligibility
  - App review prompt eligibility
  - Celebration haptic (`Theme.hapticSuccess()`)

**Source:** `PoolListView.handleRouteCompletionChange(oldCount:newCount:)` method

#### Output: `RouteOptimizationResult`

| Field | Type | Description |
|-------|------|-------------|
| `objective` | RouteOptimizationObjective | The optimization mode used |
| `currentOrderedPoolIDs` | [UUID] | Pool UUIDs in pre-optimization order |
| `orderedPoolIDs` | [UUID] | Pool UUIDs in optimized order |
| `estimatedCurrentMinutes` | Double | Total travel time for current order |
| `estimatedOptimizedMinutes` | Double | Total travel time for optimized order |
| `unresolvedStopIDs` | [UUID] | Pool UUIDs excluded (missing coordinates) |
| `usedMapKitETA` | Bool | Whether MapKit was used (vs. Haversine fallback) |
| `estimatedMinutesSaved` | Double (computed) | `max(0, estimatedCurrentMinutes - estimatedOptimizedMinutes)` |

---

## 3. Business Rules

### 3.1 Subscription Tiers

**Source:** `ViewModels/SubscriptionManager.swift`

#### Tier Definitions

| Tier | `SubscriptionTier` | `isPremiumActive` | `isTrialActive` |
|------|-------------------|-------------------|-----------------|
| Free | `.free` | `false` | `false` |
| Trial | `.trial` | `true` | `true` |
| Paid (Pro) | `.paid` | `true` | `false` |

#### Free Tier Pool Cap

```swift
static let freePoolCap = 5
```

- Free users can have up to **5 pools**
- At pool cap, the paywall is presented with context `.poolCapReached`
- CSV import also enforces the cap: `if !isPremiumActive && (pools.count + creates) > freePoolCap`

**Source:** `SubscriptionManager.freePoolCap`

#### Premium Feature Gating

| Feature (`PremiumFeature`) | Access Rule |
|---------------------------|-------------|
| `.analytics` | `isPremiumActive` only |
| `.routeOptimization` | `isPremiumActive` only |
| `.backupRestore` | `isPremiumActive` only |
| `.unlimitedPools` | `isPremiumActive` OR `poolCount < freePoolCap` |

**Source:** `SubscriptionManager.canAccess(_:poolCount:)` method

#### Paywall Contexts

| Context | Trigger | Title |
|---------|---------|-------|
| `.analyticsTab` | Tapping Analytics tab | "Unlock Analytics" |
| `.optimizeRoute` | Tapping Optimize button | "Unlock Route Optimization" |
| `.backupRestore` | Tapping Backup/Restore | "Unlock Full Backup & Restore" |
| `.poolCapReached` | Adding 6th pool on free tier | "Upgrade for Unlimited Pools" |
| `.settingsUpgrade` | Settings upgrade button | "Upgrade to PoolFlow Pro" |
| `.cloudSync` | iCloud sync section | "Unlock iCloud Sync" |

#### Trial Period

- Duration: **7 days** (inferred from `Calendar.current.date(byAdding: .day, value: 7, to: Date())`)
- Trial-ending notification scheduled 1 day before expiration
- Product IDs: `poolflow_pro_monthly`, `poolflow_pro_annual`
- Entitlement ID: `"pro"`

**Source:** `SubscriptionManager.applyTierOverride(.trial)` and `SubscriptionManager.proEntitlementID`

#### RevenueCat Integration

- Billing managed via RevenueCat SDK
- If API key is missing or configuration fails: graceful fallback to free tier
- `isBillingAvailable` flag controls whether purchase/restore buttons are enabled
- `billingUnavailableMessage` shown in Settings when billing is offline

### 3.2 Profit Analytics

**Source:** `Views/ProfitDashboardView.swift`, `Engine/DosingEngine.swift`

#### Money Loser Detection

```swift
let isMoneyLoser = pool.monthlyServiceFee > 0
    && analysis.totalChemCost > (pool.monthlyServiceFee * 0.30)
```

A pool is flagged as a "Money Loser" when chemical costs exceed **30%** of the monthly service fee within the billing period.

**Rationale:** Industry rule of thumb -- chemical costs should be < 30% of revenue to maintain healthy margins after accounting for labor, fuel, equipment, and overhead.

#### Profit Analysis Function

```swift
static func profitAnalysis(
    monthlyFee: Double,
    serviceEvents: [ServiceEvent],
    billingPeriodDays: Int = 30
) -> (totalChemCost: Double, profit: Double, isInTheRed: Bool)
```

- Filters `serviceEvents` to those within the last `billingPeriodDays` calendar days
- `totalChemCost` = sum of `serviceEvent.totalChemicalCost` for filtered events
- `profit` = `monthlyFee - totalChemCost`
- `isInTheRed` = `profit < 0` (absolute loss, distinct from the 30% money loser threshold)

**Source:** `DosingEngine.profitAnalysis(monthlyFee:serviceEvents:billingPeriodDays:)`

#### Billing Periods

Users can toggle between three periods in the Analytics dashboard:

| Period | Days |
|--------|------|
| 30-day | Last 30 calendar days from today |
| 60-day | Last 60 calendar days from today |
| 90-day | Last 90 calendar days from today |

#### Aggregate Metrics

| Metric | Calculation |
|--------|-------------|
| Total Revenue | Sum of all `pool.monthlyServiceFee` |
| Total Chemical Cost | Sum of all per-pool `totalChemCost` within period |
| Total Profit | `totalRevenue - totalChemCost` |
| Margin Ratio | `profit / monthlyFee` (per pool; -1 if fee is 0) |

#### Analytics Sort Modes

| Mode | AppStorage Key | Sort Logic |
|------|---------------|------------|
| Money Losers First | `moneyLosersFirst` | Money losers at top, then by worst profit, then alphabetical |
| Worst Margin First | `worstMarginFirst` | Ascending by `marginRatio`, then alphabetical |
| Highest Chem Spend | `highestChemSpend` | Descending by `chemCost`, then alphabetical |
| Alphabetical | `alphabetical` | By `customerName` A-Z |

**Source:** `ProfitDashboardView.AnalyticsSortMode`

### 3.3 Notification Eligibility

**Source:** `App/PoolFlowApp.swift`, `Views/QuickLogView.swift`, `Views/PoolListView.swift`

#### Eligibility Gate

Notifications are NOT requested on first launch. The user must demonstrate engagement:

```swift
let eligible = notificationPromptEligible
    || quickLogSuccessCount >= 3
    || hasCompletedRouteOnce
```

The system evaluates eligibility when:
- `quickLogSuccessCount` changes (after each successful quick log save)
- `hasCompletedRouteOnce` changes (after completing all pools for a day)

#### Triggering Conditions

| Condition | Threshold | Source |
|-----------|-----------|--------|
| Quick log count | `quickLogSuccessCount >= 3` | `QuickLogView` increments on successful save |
| Route completion | `hasCompletedRouteOnce == true` | `PoolListView` sets when all day pools serviced AND `totalDayPools >= 3` |

#### Notification Prompt Flow

1. Eligibility becomes true -> `notificationPromptEligible = true` (persisted)
2. If `!notificationPromptShown` AND `!notificationsEnabledByUser` -> show notification primer sheet
3. User accepts -> `requestAuthorization(options: [.alert, .badge, .sound])`
4. If granted -> `notificationsEnabledByUser = true` -> schedule enabled scenarios

**Source:** `PoolFlowApp.evaluateNotificationPromptEligibility()` method

### 3.4 App Store Review Prompts

**Source:** `ViewModels/AppReviewManager.swift`

#### Review Trigger Conditions

| Trigger | Condition |
|---------|-----------|
| `quickLogMilestone` | `quickLogCount` is in `{5, 15, 50}` |
| `routeComplete` | `hasCompletedRoute == true` |

#### Rate Limiting

| Rule | Value |
|------|-------|
| Minimum days between requests | **60 days** |
| Maximum requests per app version | **1** |

Both conditions must pass. The version check uses `CFBundleShortVersionString`.

**Source:** `AppReviewManager.shouldRequest(trigger:quickLogCount:hasCompletedRoute:)` method

---

## 4. Data Management

### 4.1 Backup Schema

**Source:** `ViewModels/FullBackupModels.swift`, `ViewModels/DataExportService.swift`

#### Schema Versioning

| Property | Value |
|----------|-------|
| `currentVersion` | **2** |
| `minimumSupportedVersion` | **1** |

**Source:** `FullBackupSchema.currentVersion` and `FullBackupSchema.minimumSupportedVersion`

#### Compatibility Check

```swift
var isCompatible: Bool {
    backupSchemaVersion >= minimumSupportedSchemaVersion
        && backupSchemaVersion <= maximumSupportedSchemaVersion
}
```

- Backup v1: compatible (equipment file optional, defaults to empty)
- Backup v2: compatible (includes equipment.json)
- Backup v3+: incompatible (user prompted to update app)

#### ZIP Archive Structure

```
full-backup-{timestamp}.zip/
    manifest.json
    pools.json
    service_events.json
    chemical_doses.json
    inventory.json
    customer_profiles.json
    equipment.json                 (added in schema v2; optional in v1)
    media/service-events/
        {service-event-uuid}.bin   (JPEG photo data)
```

#### File Names (Constants)

| Constant | Filename |
|----------|----------|
| `manifestFileName` | `"manifest.json"` |
| `poolsFileName` | `"pools.json"` |
| `serviceEventsFileName` | `"service_events.json"` |
| `chemicalDosesFileName` | `"chemical_doses.json"` |
| `inventoryFileName` | `"inventory.json"` |
| `customerProfilesFileName` | `"customer_profiles.json"` |
| `equipmentFileName` | `"equipment.json"` |
| `mediaDirectoryPath` | `"media/service-events"` |

#### Manifest Structure

```json
{
  "schemaVersion": 2,
  "createdAt": "ISO8601 date",
  "appVersion": "1.x.x",
  "counts": {
    "pools": 0,
    "serviceEvents": 0,
    "chemicalDoses": 0,
    "inventoryItems": 0,
    "customerProfiles": 0,
    "mediaFiles": 0,
    "equipment": 0
  }
}
```

#### What Is Included in Backups

| Entity | Fields Serialized |
|--------|-------------------|
| Pool | id, customerName, address, latitude, longitude, waterTempF, pH, calciumHardness, totalAlkalinity, totalDissolvedSolids, cyanuricAcid, monthlyServiceFee, poolVolumeGallons, notes, serviceDayOfWeek, routeOrder, cachedLSI, createdAt, updatedAt |
| ServiceEvent | id, poolID, timestamp, waterTempF, pH, calciumHardness, totalAlkalinity, cyanuricAcid, lsiValue, totalChemicalCost, techNotes, photoFileName |
| ChemicalDose | id, serviceEventID, chemicalID (nullable), quantityOz, cost |
| ChemicalInventory | id, name, chemicalTypeRaw, costPerOz, currentStockOz, unitLabel, concentration, lowStockThresholdOz |
| CustomerProfile | poolID, contactName, contactPhone, contactEmail, gateAccessType, preferredArrivalWindow, tagsCSV |
| Equipment | id, poolID, name, equipmentTypeRaw, manufacturer, modelNumber, serialNumber, installDate, warrantyExpiryDate, lastServiceDate, nextServiceDate, notes, createdAt, updatedAt |

#### Restore Process

1. Extract ZIP to temporary directory
2. Parse `manifest.json` -- validate schema version
3. Parse all JSON entity files (ISO 8601 date decoding)
4. Validate referential integrity:
   - ServiceEvent -> Pool (must exist)
   - ChemicalDose -> ServiceEvent (must exist)
   - ChemicalDose -> ChemicalInventory (nullable but if present, must exist)
   - Equipment -> Pool (if pool missing, equipment silently skipped)
5. **Delete all existing** pools, inventory items, and equipment
6. Insert all backup records in order: inventory -> pools -> service events -> chemical doses -> equipment
7. Re-attach media files to service events by UUID
8. Clear and re-import customer profiles (UserDefaults-based)
9. Save model context

#### Restore Error Types

| Error | Trigger |
|-------|---------|
| `.missingManifest` | No manifest.json in archive |
| `.unsupportedSchemaVersion(Int)` | Version outside supported range |
| `.missingRequiredFile(String)` | Required JSON file not found |
| `.invalidReference(String)` | Orphaned doses or events |
| `.unreadableArchive` | ZIP extraction failure |

### 4.2 CSV Import

**Source:** `ViewModels/DataImportService.swift`

#### Required Columns

```swift
static let requiredColumns = [
    "customer_name",
    "address"
]
```

Only 2 columns are strictly required in the header row. Rows with empty `customer_name` or `address` values are skipped with an `.error` severity issue.

Column names are normalized: lowercased, BOM/null characters stripped, non-alphanumeric characters replaced with underscores, then matched against a broad alias map (e.g., `"client"` maps to `customer_name`, `"street_address"` maps to `address`).

#### Recognized Optional Columns

| Column | Aliases | Purpose |
|--------|---------|---------|
| `service_day` | `weekday`, `day`, `service_day_of_week` | Service day of week (defaults to Monday if unrecognized) |
| `monthly_fee` | `fee`, `rate`, `price`, `monthly_service_fee` | Monthly service fee (defaults to $150.00 if absent) |
| `pool_volume` | `volume`, `gallons`, `pool_volume_gallons` | Pool volume in gallons (defaults to 15,000 if absent) |
| `notes` | `note`, `comments`, `instructions`, `service_notes` | Pool notes |
| `latitude` | `lat` | GPS latitude |
| `longitude` | `long`, `lng`, `lon` | GPS longitude |
| `contact_name` | `contact`, `contact_person`, `owner_name`, `primary_contact` | Customer contact name |
| `contact_phone` | `phone`, `telephone`, `contact_number` | Customer phone number |
| `tags` | `tag`, `labels` | Comma-separated tags |

#### Upsert Strategy: `upsertByNormalizedNameAddress`

Matching key construction:

```swift
private func normalizedKey(name: String, address: String) -> String {
    let normalizedName = name
        .lowercased()
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedAddress = address
        .lowercased()
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return "\(normalizedName)|\(normalizedAddress)"
}
```

**Match found (UPDATE):** Updates `serviceDayOfWeek`, `monthlyServiceFee` (if provided), `poolVolumeGallons` (if provided), `notes` (if non-empty, appended), `latitude`/`longitude` (if provided), `updatedAt`.

**No match (CREATE):** Creates new Pool with provided fields. Defaults: `monthlyServiceFee = 150.0`, `poolVolumeGallons = 15,000`. Assigns `routeOrder` as next available within the service day.

#### Service Day Parsing

Accepts multiple formats (evaluated in order):
1. Integer 1-7 (Sunday=1 through Saturday=7)
2. English day name (hardcoded fallback map: `"sun"` through `"saturday"`, including abbreviations like `"tue"`, `"tues"`, `"thur"`, `"thurs"`)
3. Locale-aware full weekday name (e.g., "Monday", "lundi")
4. Locale-aware short weekday name (e.g., "Mon")
5. Locale-aware very-short weekday name (e.g., "M")
6. Unrecognized: defaults to **Monday (2)** with a warning

Day tokens are normalized by stripping diacritics and non-letter characters before matching.

#### Row Limit

```swift
private let maxRows = 5_000
```

Exceeding 5,000 body rows throws `DataImportError.rowLimitExceeded(5000)`.

#### Notes Merging

When updating existing pools, notes are merged rather than replaced:

```
{incoming notes}
Contact: {contactName} • {contactPhone}
Tags: {tags}
```

Appended to existing notes with a newline separator.

#### Error Handling

- Empty `customer_name` or `address`: row skipped with `.error` severity
- Invalid `monthly_fee` or `pool_volume`: warning issued, existing/default value used
- Invalid coordinates: warning issued, existing/default coordinates used
- Persistence failure: `modelContext.rollback()` + `ImportApplyError.persistenceFailed`

#### Delimiter Auto-Detection

The importer automatically detects the best delimiter by trying all four candidates and scoring the parsed result:

| Delimiter | Character |
|-----------|-----------|
| Comma | `,` |
| Semicolon | `;` |
| Tab | `\t` |
| Pipe | `\|` |

Scoring factors: required column presence (+200 or -80 per missing), recognized column count, header width, and row-to-header column alignment across first 25 body rows.

**Source:** `DataImportService.parseBestDelimitedRows(from:)` and `scoreParsedRows(_:)` methods

#### Text Encoding Detection

Files are decoded by probing encodings in order:
1. UTF-8 with BOM (`EF BB BF`)
2. UTF-16 LE with BOM (`FF FE`)
3. UTF-16 BE with BOM (`FE FF`)
4. UTF-8 (without BOM)
5. UTF-16 LE / BE / generic UTF-16
6. ISO Latin-1

If none succeed (or content contains unexpected null characters), throws `.unreadableTextFile`.

**Source:** `DataImportService.decodeDelimitedText(from:)` method

#### Import Preview

Before applying, users see:
- **Creates:** number of new pools to insert
- **Updates:** number of existing pools to modify
- **Skips:** number of invalid rows
- **Issues:** list of warnings/errors per row (limited to first 50 displayed)

### 4.3 CloudKit Sync

**Source:** `ViewModels/CloudSyncMonitor.swift`

#### Sync Strategy

- Uses SwiftData with `NSPersistentCloudKitContainer` under the hood
- Automatic push/pull sync when iCloud account is available
- Container: `CKContainer.default()`

#### Sync Status States

| Status | Display Text |
|--------|-------------|
| `.idle` | "Idle" |
| `.syncing` | "Syncing..." |
| `.synced(Date)` | "Synced {formatted date}" |
| `.error(String)` | "Error: {message}" |
| `.accountUnavailable` | "Sign in to iCloud to enable sync" |

#### Account Status Handling

| CKAccountStatus | Response |
|----------------|----------|
| `.available` | `iCloudAvailable = true`, status = `.idle` |
| `.noAccount` | `iCloudAvailable = false`, status = `.accountUnavailable` |
| `.restricted` | `iCloudAvailable = false`, status = `.accountUnavailable` |
| `.couldNotDetermine` | `iCloudAvailable = false`, status = `.accountUnavailable` |
| `.temporarilyUnavailable` | `iCloudAvailable = false`, status = `.error(...)` |

#### Conflict Resolution

CloudKit uses last-writer-wins conflict resolution (default NSPersistentCloudKitContainer behavior). Remote changes are observed via `NSPersistentCloudKitContainer.eventChangedNotification`.

#### What Data Syncs

All SwiftData `@Model` entities sync when iCloud is available and the user has Pro:
- Pool (including all fields and relationships)
- ServiceEvent (including photo data via `.externalStorage`)
- ChemicalDose
- ChemicalInventory
- Equipment

**Not synced:** CustomerProfile data (stored in UserDefaults), AppStorage preferences, notification settings.

#### Subscription Gate

iCloud sync is gated behind Pro subscription. Free users see "Upgrade to Pro to enable iCloud sync across devices."

---

## 5. Validation Rules

### 5.1 Pool Form Validation

**Source:** `Views/PoolFormFields.swift`

#### Monthly Fee

| Rule | Validation |
|------|-----------|
| Empty | "Enter monthly fee" |
| Non-numeric | "Enter a valid number" |
| `fee <= 0` | "Fee must be greater than 0" |

#### Pool Volume

| Rule | Validation (Imperial) | Validation (Metric) |
|------|----------------------|---------------------|
| Empty | "Enter pool volume" | "Enter pool volume" |
| Non-numeric | "Enter a valid number" | "Enter a valid number" |
| Below minimum | "Minimum 1,000 gal" | "Minimum 3,785 L" |
| Above maximum | "Maximum 200,000 gal" | "Maximum 757,082 L" |

**Source:** `PoolFormFields.validatePoolVolume(_:)` method

#### Customer Name and Address

- Required fields (enforced at CSV import level: empty values cause row skip)
- No explicit character limit in form validation
- Address field activates `MKLocalSearchCompleter` after 3+ characters

### 5.2 Input Ranges (Readings)

Used in both DosingCalculatorView and QuickLogView:

| Parameter | Min | Max | Step | Unit |
|-----------|-----|-----|------|------|
| pH | 6.0 | 9.0 | 0.1 | -- |
| Temperature (Imperial) | 32 | 120 | 2 | F |
| Temperature (Metric) | 0 | 49 | 1 | C |
| Calcium Hardness | 0 | 1,000 | 25 | ppm |
| Total Alkalinity | 0 | 500 | 10 | ppm |
| Cyanuric Acid | 0 | 300 | 10 | ppm |
| TDS | 0 | 5,000 | 100 | ppm |

**Source:** `UnitManager.temperatureInputRange()` and `ReadingInputComponent` configurations

### 5.3 Volume Input Ranges

| Mode | Min | Max | Step |
|------|-----|-----|------|
| Imperial | 5,000 gal | 50,000 gal | 1,000 |
| Metric | 19,000 L | 189,000 L | 1,000 |

**Source:** `UnitManager.volumeInputRange()` and `UnitManager.volumeStep()`

### 5.4 Inventory Validation

**Low Stock Detection:**

```swift
var isLowStock: Bool {
    lowStockThresholdOz > 0 && currentStockOz < lowStockThresholdOz
}
```

Items are flagged when current stock drops below the user-defined threshold (and the threshold is non-zero).

**Source:** `ChemicalInventory.isLowStock`

### 5.5 Equipment Validation

```swift
var isWarrantyExpired: Bool {
    guard let expiry = warrantyExpiryDate else { return false }
    return expiry < Date()
}

var isServiceOverdue: Bool {
    guard let nextService = nextServiceDate else { return false }
    return nextService < Date()
}
```

**Source:** `Models/Equipment.swift`

### 5.6 Data Health Checks

Displayed in Settings:

| Check | Threshold | Source |
|-------|-----------|--------|
| Missing Coordinates | `latitude == 0.0 && longitude == 0.0` | `SettingsView.missingCoordinatesCount` |
| Missing Service Fee | `monthlyServiceFee <= 0` | `SettingsView.missingFeeCount` |
| Stale Service | Last ServiceEvent > **35 days** ago (or no events) | `SettingsView.staleServiceCount` |

---

## 6. Notification Scheduling

**Source:** `ViewModels/NotificationManager.swift`

### 6.1 Scenario Details

#### Morning Route Summary

| Property | Value |
|----------|-------|
| Identifier | `"poolflow.notification.morningRouteSummary.{weekday}"` |
| Trigger | `UNCalendarNotificationTrigger` -- repeating weekly per service day |
| Time | User-configurable (default: 7:00 AM = `7 * 3600.0` seconds from midnight) |
| Frequency | One per weekday that has pools (e.g., Mon/Wed/Fri = 3/week) |
| Title | "Today's Route" |
| Body | "You have {N} pool(s) scheduled today." |
| Sound | `.default` |

#### Low-Stock for Tomorrow

| Property | Value |
|----------|-------|
| Identifier | `"poolflow.notification.lowStockForTomorrow"` |
| Trigger | `UNCalendarNotificationTrigger` -- tomorrow at **6:30 PM (18:30)**, non-repeating (rescheduled on each config change) |
| Conditions | Pools scheduled tomorrow AND at least one `isLowStock` chemical |
| Title | "Prep for Tomorrow" |
| Body | "{N} low-stock chemical(s) before {M} scheduled stop(s)." |
| Sound | `.default` |
| **Suppression Rule** | Suppressed when Morning Route Summary is enabled (max one operational notification per day) |

#### Weekly Digest

| Property | Value |
|----------|-------|
| Identifier | `"poolflow.notification.weeklyDigest"` |
| Trigger | `UNCalendarNotificationTrigger` -- **Sunday at 5:00 PM (17:00)** |
| Title | "Weekly PoolFlow Digest" |
| Body | "{N} active pools. Review analytics and route health before the new week." |
| Sound | `.default` |

#### Trial Expiring Reminder

| Property | Value |
|----------|-------|
| Identifier | `"poolflow.notification.trialExpiring"` |
| Trigger | `UNCalendarNotificationTrigger` -- **1 day before trial expiration**, non-repeating |
| Condition | `reminderDate > Date()` (only if trial hasn't already expired) |
| Title | "Your PoolFlow Pro trial ends tomorrow" |
| Body | "Upgrade now to keep unlimited pools, analytics, and route optimization." |
| Sound | `.default` |

### 6.2 Scheduling Behavior

- On any configuration change (toggle, time change): all pending notifications are **removed** and **rescheduled**
- `center.removeAllPendingNotificationRequests()` is called first
- Failures are logged but silently ignored (notifications are non-critical)
- Authorization requested with options: `[.alert, .badge, .sound]`
- The `NotificationManager` uses protocol-based dependency injection (`UserNotificationCenterClient`) for testability

---

## 7. Chemical Inventory System

**Source:** `Models/ChemicalInventory.swift`

### 7.1 Chemical Types

| Type | Raw Value | Classification |
|------|-----------|---------------|
| `.acid` | `"acid"` | Liquid |
| `.base` | `"base"` | Dry |
| `.calcium` | `"calcium"` | Dry |
| `.alkalinity` | `"alkalinity"` | Dry |
| `.chlorine` | `"chlorine"` | Liquid |
| `.stabilizer` | `"stabilizer"` | Dry |
| `.dilution` | `"dilution"` | N/A |
| `.none` | `"none"` | N/A |

### 7.2 Default Chemical Catalog (Seed Data)

| Name | Type | Cost/oz | Initial Stock | Concentration |
|------|------|---------|---------------|---------------|
| Muriatic Acid (31.45%) | acid | $0.05 | 256 oz (2 gal) | 31.45% |
| Soda Ash (Sodium Carbonate) | base | $0.09 | 160 oz (10 lbs) | 100% |
| Calcium Chloride (Hardness Up) | calcium | $0.07 | 400 oz (25 lbs) | 77% |
| Sodium Bicarbonate (Alkalinity Up) | alkalinity | $0.04 | 320 oz (20 lbs) | 100% |
| Trichlor Tabs (Stabilized Chlorine) | chlorine | $0.18 | 400 oz (25 lbs) | 90% |
| Liquid Chlorine (12.5% Sodium Hypochlorite) | chlorine | $0.02 | 512 oz (4 gal) | 12.5% |
| Cyanuric Acid (Stabilizer) | stabilizer | $0.12 | 64 oz (4 lbs) | 100% |

**Source:** `ChemicalInventory.defaultCatalog()` method

This catalog is re-seeded automatically when the user performs "Clear All App Data."

---

## 8. Equipment Tracking

**Source:** `Models/Equipment.swift`

### 8.1 Equipment Types

| Type | Raw Value | Display Name |
|------|-----------|-------------|
| `.pump` | `"pump"` | Pump |
| `.filter` | `"filter"` | Filter |
| `.heater` | `"heater"` | Heater |
| `.cleaner` | `"cleaner"` | Cleaner |
| `.saltSystem` | `"saltSystem"` | Salt System |
| `.automation` | `"automation"` | Automation |
| `.light` | `"light"` | Light |
| `.cover` | `"cover"` | Cover |
| `.other` | `"other"` | Other |

### 8.2 Equipment Fields

| Field | Type | Description |
|-------|------|-------------|
| name | String | Equipment name |
| equipmentType | EquipmentType | Category |
| manufacturer | String | Manufacturer name |
| modelNumber | String | Model number |
| serialNumber | String | Serial number |
| installDate | Date? | Installation date |
| warrantyExpiryDate | Date? | Warranty expiration |
| lastServiceDate | Date? | Most recent service |
| nextServiceDate | Date? | Next scheduled service |
| notes | String | Freeform notes |

Equipment is linked to a Pool via a cascade-delete relationship (`Pool.equipment`).

---

## 9. Unit System

**Source:** `App/UnitSystem.swift`

### 9.1 Storage Convention

All internal storage uses imperial units:
- Temperature: Fahrenheit
- Volume: Gallons
- Dosing quantities: Ounces

The `UnitManager` converts for **display only**.

### 9.2 Conversion Constants

| Conversion | Factor |
|-----------|--------|
| Gallons to Liters | 3.78541 |
| Oz to mL | 29.5735 |
| Oz to Grams | 28.3495 |
| Lbs to Kg | 0.453592 |
| F to C | `(F - 32) * 5/9` |
| C to F | `C * 9/5 + 32` |

### 9.3 Auto-Detection

On first launch, the unit system is auto-detected from the user's locale:
- Region `"US"` -> Imperial
- All other regions -> Metric
- Persisted so auto-detection only runs once

### 9.4 Dual-Unit Display

When `showBothUnits` is enabled, values display in both systems:
- Imperial primary: `"78F (26C)"`
- Metric primary: `"26C (78F)"`

---

## 10. Customer Profiles

**Source:** `ViewModels/CustomerProfileViewModel.swift`

### 10.1 Storage

Customer profiles are stored in **UserDefaults** (not SwiftData) with key format: `"customerProfile.{poolID-uuid}"`.

### 10.2 Profile Fields

| Field | Type | Description |
|-------|------|-------------|
| contactName | String | Customer contact name |
| contactPhone | String | Phone number |
| contactEmail | String | Email address |
| gateAccessType | String | Gate/access instructions |
| preferredArrivalWindow | String | Preferred service time |
| tagsCSV | String | Comma-separated tags |

### 10.3 Behavior

- Empty profiles are automatically removed from UserDefaults
- Profiles are included in full backup export and restored on import
- `clearAllProfiles()` removes all keys with the `"customerProfile."` prefix
- `hasAnyValue` computed property returns true if any field is non-empty

---

## 11. QuickLog Workflow

**Source:** `Views/QuickLogView.swift`

### 11.1 Save Sequence

```
1. Create ServiceEvent
   +-- Set water readings from form inputs
   +-- Calculate LSI via LSICalculator
   +-- Set lsiValue on the event
   +-- Set timestamp to Date.now
   +-- Link to Pool
   +-- Set totalChemicalCost from dosing recommendations

2. Create ChemicalDose records (for each confirmed recommendation)
   +-- Set quantityOz from dosing engine
   +-- Set cost (from inventory costPerOz * quantity)
   +-- Link to ServiceEvent
   +-- Link to ChemicalInventory (if matched)

3. Decrement inventory stock
   +-- For each ChemicalDose: inventory.currentStockOz -= dose.quantityOz

4. Update Pool
   +-- Copy water readings to pool-level fields
   +-- Recalculate cachedLSI
   +-- Update updatedAt timestamp

5. Increment quickLogSuccessCount (AppStorage)
   +-- If count >= 3: set notificationPromptEligible = true
   +-- Evaluate guide tooltips

6. Save model context
```

### 11.2 Undo Mechanism

After save, an undo toast appears. Undo action:

1. Delete the ServiceEvent (cascades to ChemicalDoses)
2. Restore pool-level readings to previous snapshot values
3. Recalculate cachedLSI
4. Decrement quickLogSuccessCount
5. Restore notificationPromptEligible to previous value
6. Save model context

### 11.3 Optional Confirmation

If `quickLogConfirmBeforeSave == true` (AppStorage toggle), a confirmation dialog appears before saving.

---

## 12. Address Autocomplete and Geocoding

**Source:** `ViewModels/AddressSearchCompleter.swift`, `Views/PoolFormFields.swift`

### 12.1 Autocomplete Flow

1. User types in address field (minimum 3 characters, trimmed)
2. `MKLocalSearchCompleter` returns suggestions
3. Up to **5 suggestions** displayed in a dropdown overlay
4. User taps a suggestion -> `MKLocalSearch` resolves full address
5. Address, latitude, and longitude populated on the form
6. On resolution failure: address is set to `"{title}, {subtitle}"`, coordinates remain (0, 0)

### 12.2 State Management

- `suppressAddressQueryUpdate` flag prevents re-triggering autocomplete after programmatic address updates
- `selectionToken` (UUID) prevents stale async resolutions from overwriting current selection
- `beginSuggestionSelection()` / `finishSuggestionSelection()` prevents flickering during async resolve
- Suggestions cleared on field blur and on view disappear

### 12.3 Coordinate Handling

- Failed geocoding leaves coordinates at (0.0, 0.0)
- Pools with (0.0, 0.0) appear in Settings > Data Health > "Missing Coordinates"
- Route optimization treats (0.0, 0.0) pools as unresolved stops

---

## 13. Error Handling

### 13.1 Store Startup State Machine

```
StoreStartupState:
  .loading --> attempt ModelContainer init
     |
     +-- Success --> .ready(ModelContainer)
     |                  +-- Seed default chemicals if inventory empty
     |
     +-- Failure --> .recovery(StoreFailureContext)
                       +-- Retry  -> back to .loading
                       +-- Reset  -> delete DB, back to .loading
                       +-- Restore -> file picker -> import -> .loading
```

### 13.2 Error Enums

#### DataExportError
- `.poolNotFound` -- selected pool could not be found
- `.emptyData` -- no data available to export
- `.backupCreationFailed` -- unable to create backup archive

#### DataImportError
- `.missingRequiredColumns([String])` -- CSV missing required headers (`customer_name`, `address`)
- `.rowLimitExceeded(Int)` -- CSV exceeds 5,000 rows
- `.unreadableTextFile` -- file could not be decoded as UTF-8, UTF-16, or ISO Latin-1

#### ImportApplyError
- `.persistenceFailed(String)` -- save failed, rollback executed

#### FullBackupImportError
- `.missingManifest` -- no manifest.json in archive
- `.unsupportedSchemaVersion(Int)` -- version outside supported range
- `.missingRequiredFile(String)` -- required JSON file not found
- `.invalidReference(String)` -- orphaned doses, events, or chemicals
- `.unreadableArchive` -- ZIP extraction failure

### 13.3 Graceful Degradation

| Subsystem | Failure | Behavior |
|-----------|---------|----------|
| RevenueCat | API key missing or init failure | Free-tier fallback, billing buttons disabled |
| MapKit ETA | Network error or timeout | Haversine approximation + 28 mph + 1.5 min |
| Notification scheduling | Authorization denied or scheduling error | Silent failure, logged only |
| Geocoding | Resolution failure | Coordinates stay at (0, 0), flagged in Data Health |
| iCloud | Account unavailable | Status shows "Sign in to iCloud", sync disabled |

---

## 14. Haptic Feedback System

**Source:** `App/Theme.swift`, `ViewModels/DosingViewModel.swift`

### 14.1 Triggers

| Context | Condition | Haptic Type |
|---------|-----------|-------------|
| LSI crosses into Balanced | LSI enters -0.3 to +0.3 | `hapticSuccess()` |
| LSI crosses into Scale-Forming | LSI exceeds +0.3 | `hapticWarning()` |
| LSI crosses into Corrosive | LSI drops below -0.3 | `hapticError()` |
| Input at boundary | Slider/stepper at min or max | `hapticLight()` (increment) / `hapticError()` (at limit) |
| Quick log saved | Service event persisted | `hapticSuccess()` |
| Route completed | All day pools serviced | `hapticSuccess()` |

### 14.2 LSI Status Change Detection

`DosingViewModel.checkHapticTrigger()` fires haptics only when the LSI status **changes** -- not on every recalculation. It tracks `previousStatus` to prevent haptic spam during continuous slider adjustment.

---

## 15. Hardcoded Business Constants Summary

| Constant | Value | Location |
|----------|-------|----------|
| Free tier pool cap | 5 | `SubscriptionManager.freePoolCap` |
| Money loser threshold | 30% of monthly fee | `ProfitDashboardView` |
| Muriatic acid dose per 0.2 pH per 10K gal | 26 oz | `DosingEngine` |
| Soda ash dose per 0.2 pH per 10K gal | 6 oz | `DosingEngine` |
| Sodium bicarb dose per 10 ppm TA per 10K gal | 24 oz | `DosingEngine` |
| Calcium chloride dose per 10 ppm CH per 10K gal | 20 oz | `DosingEngine` |
| Fallback nudge (base, corrosive) | 3 oz * volumeFactor | `DosingEngine` |
| Fallback nudge (acid, scaling) | 8 oz * volumeFactor | `DosingEngine` |
| Corrosive pH target | 7.4 | `DosingEngine` |
| Scaling pH target | 7.6 | `DosingEngine` |
| Corrosive TA target | 80 ppm | `DosingEngine` |
| Scaling TA target | 120 ppm | `DosingEngine` |
| Corrosive CH target | 200 ppm | `DosingEngine` |
| High CH threshold (dilution) | 400 ppm | `DosingEngine` |
| LSI balanced range | -0.3 to +0.3 | `LSICalculator` |
| Default TDS constant | 12.10 (at 1000 ppm) | `LSICalculator` |
| CYA alkalinity correction | TA - (CYA / 3) | `LSICalculator` |
| Backup schema version | 2 | `FullBackupSchema` |
| Minimum backup version | 1 | `FullBackupSchema` |
| CSV required columns | 2 (`customer_name`, `address`) | `DataImportService.requiredColumns` |
| CSV row limit | 5,000 | `DataImportService` |
| CSV default service day fallback | Monday (2) | `DataImportService.stageCustomersRows` |
| Default cost/oz acid | $0.05 | `DosingEngine.CostLookup.defaults` |
| Default cost/oz base | $0.09 | `DosingEngine.CostLookup.defaults` |
| Default cost/oz calcium | $0.07 | `DosingEngine.CostLookup.defaults` |
| Default cost/oz alkalinity | $0.04 | `DosingEngine.CostLookup.defaults` |
| Default cost/oz chlorine | $0.02 | `DosingEngine.CostLookup.defaults` |
| Default cost/oz stabilizer | $0.12 | `DosingEngine.CostLookup.defaults` |
| Scaling TA acid multiplier | 0.5 (half normal acid dose) | `DosingEngine` |
| Min pools for route optimization | 3 | `RouteOptimizationEngine` |
| Review minimum gap | 60 days | `AppReviewManager` |
| Review milestones | {5, 15, 50} quick logs | `AppReviewManager` |
| Notification eligibility | 3 quick logs OR 1 route | `PoolFlowApp` |
| Route completion minimum | 3 pools in a day | `PoolListView` |
| Stale service threshold | 35 days | `SettingsView` |
| Haversine earth radius | 3,958.8 miles | `TravelTimeEstimator` |
| Fallback driving speed | 28 mph | `TravelTimeEstimator` |
| Per-leg overhead | 1.5 minutes | `TravelTimeEstimator` |
| Balanced route displacement penalty | 0.6 min/position | `RouteOptimizationEngine` |
| 2-opt max passes | 2 | `RouteOptimizationEngine` |
| 2-opt improvement threshold | -0.01 | `RouteOptimizationEngine` |
| Default pool volume | 15,000 gal | `WaterChemistryDefaults` |
| Default monthly fee | $150.00 | `WaterChemistryDefaults` |
| Default pH | 7.4 | `WaterChemistryDefaults` |
| Default water temp | 78 F | `WaterChemistryDefaults` |
| Default calcium hardness | 250 ppm | `WaterChemistryDefaults` |
| Default total alkalinity | 100 ppm | `WaterChemistryDefaults` |
| Default TDS | 1,000 ppm | `WaterChemistryDefaults` |
| Default CYA | 30 ppm | `WaterChemistryDefaults` |
| Default route summary time | 7:00 AM (25,200 sec) | `SettingsView` |
| Low stock reminder time | 6:30 PM (18:30) | `NotificationManager` |
| Weekly digest time | Sunday 5:00 PM | `NotificationManager` |
| Trial expiry reminder | 1 day before | `NotificationManager` |
| Pool volume validation min (imperial) | 1,000 gal | `PoolFormFields` |
| Pool volume validation max (imperial) | 200,000 gal | `PoolFormFields` |
| Pool volume validation min (metric) | 3,785 L | `PoolFormFields` |
| Pool volume validation max (metric) | 757,082 L | `PoolFormFields` |
| Volume slider range (imperial) | 5,000 -- 50,000 gal | `UnitManager.volumeInputRange()` |
| Volume slider range (metric) | 19,000 -- 189,000 L | `UnitManager.volumeInputRange()` |
| Temperature slider range (imperial) | 32 -- 120 F | `UnitManager.temperatureInputRange()` |
| Temperature slider range (metric) | 0 -- 49 C | `UnitManager.temperatureInputRange()` |
| Gallons to Liters conversion | 3.78541 | `UnitManager` |
| Oz to mL conversion | 29.5735 | `UnitManager` |
| Oz to grams conversion | 28.3495 | `UnitManager` |
| Max address suggestions | 5 | `PoolFormFields` |
| Min address query length | 3 characters | `PoolFormFields` |

---

*This document specifies how PoolFlow features operate at a behavioral level, with all values extracted directly from source code. For the feature list, see [03_Feature_Inventory](03_Feature_Inventory.md). For user workflows, see [05_Customer_Journeys](05_Customer_Journeys.md).*
