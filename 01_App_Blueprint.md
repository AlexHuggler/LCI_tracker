# PoolFlow -- App Blueprint

> **Document:** 01_App_Blueprint
> **Version:** 2.1
> **Last Updated:** 2026-02-25
> **Bundle ID:** `alex.PoolFlow`
> **Marketing Version:** 1.0 (Build 1)
> **Related Docs:** [02_Product_Strategy](02_Product_Strategy.md) | [03_Feature_Inventory](03_Feature_Inventory.md) | [04_Functional_Scope](04_Functional_Scope.md) | [05_Customer_Journeys](05_Customer_Journeys.md)

---

## 1. Overview

PoolFlow is a native iOS application built for pool service professionals. It provides an end-to-end workflow for managing a route-based pool service business: tracking customer pools and their water chemistry, calculating the Langelier Saturation Index (LSI), generating actionable chemical dosing recommendations, logging service visits with proof-of-service photos, managing chemical inventory with low-stock alerts, tracking per-pool profitability, optimizing daily service routes, and managing pool equipment records.

The app follows an **offline-first design** -- all data is persisted locally via SwiftData and optionally synced across devices through iCloud/CloudKit for Pro subscribers. Monetization is handled through a freemium model with RevenueCat-managed subscriptions (monthly and annual), with a free tier capped at 5 pools.

**Total Swift Source Files:** ~81
**Xcode Project:** `PoolFlow.xcodeproj`

---

## 2. Tech Stack

| Layer | Technology | Version / Detail | Purpose |
|---|---|---|---|
| **Language** | Swift | 5.0 (`SWIFT_VERSION`), with `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` | Primary language |
| **UI Framework** | SwiftUI | iOS 17.6+ | Declarative UI with `@Observable`, `@Query`, `@AppStorage` |
| **Persistence** | SwiftData | `@Model` macro | Offline-first local SQLite-backed ORM |
| **Cloud Sync** | CloudKit | Container: `iCloud.com.poolflow.app` | Cross-device data sync (Pro subscribers only) |
| **Subscriptions** | RevenueCat | `purchases-ios-spm` v5.59.2 | Subscription lifecycle, entitlement checks, paywall gating |
| **In-App Purchases** | StoreKit 2 | Sandbox `.storekit` config | Review prompts via `SKStoreReviewController`; sandbox testing |
| **Mapping & Directions** | MapKit + CoreLocation | `MKDirections`, `MKLocalSearchCompleter`, `MKLocalSearch` | Route ETA estimation, address autocomplete, geocoding |
| **Archive / Backup** | ZIPFoundation | v0.9.20 | Full backup export/restore as `.zip` archives |
| **PDF Generation** | UIKit | `UIGraphicsPDFRenderer` | Customer visit reports and monthly performance PDFs |
| **Notifications** | UserNotifications | `UNUserNotificationCenter` | Morning route summary, low-stock alerts, weekly digest, trial expiry |
| **Haptics** | UIKit | Pre-warmed `UIFeedbackGenerator` instances | Tactile feedback on LSI status changes and user actions |
| **Localization** | Xcode String Catalogs | `Localizable.xcstrings` | All user-facing strings localized via `String(localized:)` |
| **Logging** | `os.Logger` | Unified Logging | Subsystem: `com.poolflow.app`; categories: `DataStore`, `Subscription`, `DataExport`, `DataImport`, `Notifications` |

### SPM Dependencies (Package.resolved)

| Package | Source | Pinned Version |
|---|---|---|
| `purchases-ios-spm` | `https://github.com/RevenueCat/purchases-ios-spm` | 5.59.2 |
| `ZIPFoundation` | `https://github.com/weichsel/ZIPFoundation.git` | 0.9.20 |

### What Is NOT Included

- No remote backend or custom API server
- No analytics SDK (no Mixpanel, Firebase Analytics, etc.)
- No crash reporting SDK (no Crashlytics, Sentry, etc.)
- No authentication service
- No third-party UI libraries

---

## 3. Architecture Pattern

### MVVM with Engine Layer

PoolFlow follows **MVVM with a dedicated Engine layer**, keeping calculation logic separate from presentation and persistence.

```
+---------------------------------------------------------+
|                      SwiftUI Views                       |
|  (PoolListView, QuickLogView, DosingCalculatorView...)   |
+---------------------------------------------------------+
|                    @Observable ViewModels                 |
|  (DosingViewModel, PoolListViewModel,                    |
|   SubscriptionManager, RouteOptimizationEngine...)       |
+---------------------------------------------------------+
|                     Engine Layer                         |
|  (LSICalculator, DosingEngine, DosingFormatter,          |
|   HybridTravelTimeEstimator)                             |
+---------------------------------------------------------+
|                    Services Layer                         |
|  (DataExportService, DataImportService, BackupCodec,     |
|   NotificationManager, PDFReportRenderer, AppServices)   |
+---------------------------------------------------------+
|                     @Model Entities                      |
|  (Pool, ServiceEvent, ChemicalDose,                      |
|   ChemicalInventory, Equipment)                          |
+---------------------------------------------------------+
|   SwiftData (SQLite) + CloudKit (Pro) + UserDefaults     |
+---------------------------------------------------------+
```

### Key Architectural Decisions

- **ViewModels as `@Observable` classes** -- Swift observation protocol for reactive state updates without `@Published` boilerplate.
- **Engine layer is pure logic** -- `LSICalculator` and `DosingEngine` are stateless structs/enums with static methods. No persistence or UI dependencies. Fully unit-testable.
- **Services are `@MainActor`-isolated** -- `DataExportService`, `DataImportService`, `NotificationManager`, and `RouteOptimizationEngine` run on the main actor for safe SwiftData access.
- **`HybridTravelTimeEstimator` is an `actor`** -- Thread-safe caching of MapKit ETA responses with haversine-distance fallback.
- **Singleton pattern for cross-cutting concerns** -- `SubscriptionManager.shared`, `NotificationManager.shared`, `DataImportService.shared`.

### All Architectural Components

| Component | Type | Role |
|---|---|---|
| `PoolFlowApp` | `@main App` | Entry point; `StoreStartupState` flow, creates `ModelContainer` with 5-model schema, RevenueCat init, CloudKit conditional enable, seeds default inventory, store recovery with retry/reset/restore |
| `ContentView` | `View` | Root tab/sidebar navigation; adapts layout for iPhone (`TabView`) vs iPad (`NavigationSplitView`) |
| `DosingViewModel` | `@Observable` | Binds water chemistry inputs to `LSICalculator` and `DosingEngine`; creates `ServiceEvent` records |
| `PoolListViewModel` | `@Observable` | Manages day-of-week filtering and drag-and-drop route reordering |
| `SubscriptionManager` | `@Observable` singleton | RevenueCat integration; entitlement checks; paywall presentation logic; UI test overrides |
| `CloudSyncMonitor` | `@Observable` | Monitors iCloud account status and remote change notifications |
| `NotificationManager` | `@MainActor` singleton | Schedules local notifications (morning summary, low stock, weekly digest, trial expiry) |
| `AppReviewManager` | Static enum | Milestone-based `SKStoreReviewController` prompts (5/15/50 quick logs, route completion) |
| `RouteOptimizationEngine` | `@MainActor` class | Nearest-neighbor + 2-opt route optimization |
| `HybridTravelTimeEstimator` | `actor` | MapKit ETA with haversine-distance fallback; result caching |
| `AddressSearchCompleter` | `@Observable` | Debounced `MKLocalSearchCompleter` wrapper for address autocomplete (250ms, min 3 chars) |
| `CustomerProfileViewModel` | `@Observable` | CRUD for customer contact/gate/tag profiles stored in `UserDefaults` |
| `OnboardingFlowViewModel` | `@Observable` | Multi-step onboarding with profiling questions, branching logic, inline pool creation |
| `OnboardingGuideManager` | `@Observable` | Post-onboarding contextual tooltip system (4 tooltips, each shown once) |
| `DataExportService` | `@MainActor` class | CSV, PDF, and full backup ZIP export |
| `DataImportService` | `@MainActor` singleton | CSV customer import with upsert merge strategy; full backup restore with referential integrity checks |
| `PDFReportRenderer` | Struct | Renders Customer Visit Report and Monthly Performance PDFs via `UIGraphicsPDFRenderer` |
| `DosingFormatter` | Struct | Unit-system-aware quantity and instruction formatting for dosing recommendations |
| `UnitManager` | `@Observable` | Imperial/metric preference with runtime conversion for temperature, volume, and dosing quantities |
| `AppServices` | `@MainActor @Observable` singleton | Dependency container holding `SubscriptionManager`, `NotificationManager`, `DataImportService`, `DataExportService`, `CustomerProfileViewModel` factory; injected via `@Environment` |
| `AppLocaleResolver` | Static enum | Resolves UI locale from language override + device region; provides `uiLocale` and `formattingLocale`; ensures valid currency for formatting |
| `AppFormatters` | Static enum | Locale-aware number, currency, and signed-number formatting helpers |
| `AppStrings` | Static enum | Runtime string localization with bundle resolution for language overrides |
| `ZIPBackupCodec` | `actor` | `BackupCodec` conformance: extracts/creates ZIP backup archives with JSON + media payloads via ZIPFoundation |

### Data Flow

```
User Input (SwiftUI Views)
    |
    v
ViewModel (@Observable)  <-->  Engine Layer (LSICalculator, DosingEngine)
    |
    v
SwiftData Models (@Model)  <-->  ModelContainer (SQLite)
    |                                    |
    v                                    v
@Query (reactive views)           CloudKit (Pro only, automatic sync)
```

### State Management

| Mechanism | Usage |
|---|---|
| `@Model` (SwiftData) | All persistent domain data: `Pool`, `ServiceEvent`, `ChemicalDose`, `ChemicalInventory`, `Equipment` |
| `@Observable` | ViewModel state, subscription status, cloud sync status, unit preferences, onboarding flow |
| `@Query` | Reactive SwiftUI data binding from SwiftData store (e.g., `@Query(sort: \Pool.routeOrder)`) |
| `@AppStorage` | User preferences via centralized `AppStorageKey` enum (~45 keys covering appearance, language, units, notifications, onboarding profiling, review tracking, feature flags, guide tooltips, import launch modes) |
| `UserDefaults` | Customer profiles (JSON-encoded per pool ID via `CustomerProfileViewModel`) |
| `@State` / `@Binding` | Ephemeral view state (sheets, selections, form fields) |
| `@Environment` | `AppServices`, `UnitManager`, `CloudSyncMonitor`, `ModelContext`, `Locale`, `horizontalSizeClass`, `scenePhase` |

---

## 4. Data Model

### Entity-Relationship Diagram

```
Pool (1)  ---cascade--->  ServiceEvent (*)  ---cascade--->  ChemicalDose (*)
  |                                                              |
  |                                                         nullify
  +---cascade--->  Equipment (*)                  ChemicalInventory (1)

CustomerProfileData  -- stored in UserDefaults keyed by Pool.id
```

### Relationship Delete Rules

| Parent | Child | Delete Rule |
|---|---|---|
| Pool | ServiceEvent | **Cascade** -- deleting a pool removes all service history |
| Pool | Equipment | **Cascade** -- deleting a pool removes all equipment records |
| ServiceEvent | ChemicalDose | **Cascade** -- deleting a service event removes its doses |
| ChemicalInventory | ChemicalDose | **Nullify** -- deleting inventory preserves dose records (cost archived on dose) |

---

### Pool (`@Model`)

The core entity representing a customer's swimming pool.

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Primary key |
| `customerName` | `String` | `""` | Customer display name |
| `address` | `String` | `""` | Full street address |
| `latitude` | `Double` | `0.0` | Geocoded latitude for routing |
| `longitude` | `Double` | `0.0` | Geocoded longitude for routing |
| `waterTempF` | `Double` | `78.0` | Water temperature in Fahrenheit |
| `pH` | `Double` | `7.4` | Water pH level |
| `calciumHardness` | `Double` | `250.0` | Calcium hardness in ppm |
| `totalAlkalinity` | `Double` | `100.0` | Total alkalinity in ppm |
| `totalDissolvedSolids` | `Double` | `1000.0` | TDS in ppm |
| `cyanuricAcid` | `Double` | `30.0` | CYA (stabilizer) in ppm |
| `monthlyServiceFee` | `Double` | `150.0` | Monthly billing amount |
| `poolVolumeGallons` | `Double` | `15000.0` | Pool volume in gallons |
| `notes` | `String` | `""` | Free-text notes |
| `serviceDayOfWeek` | `Int` | `2` | 1=Sunday ... 7=Saturday |
| `routeOrder` | `Int` | `0` | Position in daily route (drag-and-drop) |
| `cachedLSI` | `Double` | `0.0` | Pre-calculated LSI to avoid recalculation in list views |
| `createdAt` | `Date` | `Date()` | Record creation timestamp |
| `updatedAt` | `Date` | `Date()` | Last modification timestamp |

**Relationships:**
- `serviceEvents: [ServiceEvent]` -- cascade delete, inverse `\ServiceEvent.pool`
- `equipment: [Equipment]` -- cascade delete

**Methods & Computed Properties:**
- `waterTempCelsius: Double` -- display-only Celsius conversion
- `poolVolumeLiters: Double` -- display-only liter conversion
- `latestReadings() -> WaterReadings` -- resolves most recent `ServiceEvent` readings, falls back to pool defaults
- `recalculateLSI()` -- updates `cachedLSI` from current readings via `LSICalculator`

---

### ServiceEvent (`@Model`)

A single service visit to a pool. Captures water readings at time of service, chemicals applied, a proof-of-service photo, and the total chemical cost.

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Primary key |
| `pool` | `Pool?` | `nil` | Parent pool reference |
| `timestamp` | `Date` | `Date()` | Visit timestamp |
| `waterTempF` | `Double` | `78.0` | Readings at time of service |
| `pH` | `Double` | `7.4` | |
| `calciumHardness` | `Double` | `250.0` | |
| `totalAlkalinity` | `Double` | `100.0` | |
| `cyanuricAcid` | `Double` | `30.0` | |
| `lsiValue` | `Double` | `0.0` | Calculated LSI at time of service |
| `photoData` | `Data?` | `nil` | Proof-of-service JPEG, `@Attribute(.externalStorage)` |
| `totalChemicalCost` | `Double` | `0.0` | Sum of chemical costs for this visit |
| `techNotes` | `String` | `""` | Technician notes |

**Relationships:**
- `chemicalDoses: [ChemicalDose]` -- cascade delete, inverse `\ChemicalDose.serviceEvent`

---

### ChemicalDose (`@Model`)

A specific chemical dose applied during a service event. Links to `ChemicalInventory` for cost lookups.

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Primary key |
| `serviceEvent` | `ServiceEvent?` | `nil` | Parent event |
| `chemical` | `ChemicalInventory?` | `nil` | Linked inventory item |
| `quantityOz` | `Double` | `0.0` | Amount applied in ounces |
| `cost` | `Double` | `0.0` | Cost of this dose |

---

### ChemicalInventory (`@Model`)

Represents a chemical product the operator carries on the truck. Tracks cost-per-unit for profit calculations.

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Primary key |
| `name` | `String` | `""` | Product name |
| `chemicalTypeRaw` | `String` | `"none"` | Stored enum raw value for SwiftData compatibility |
| `costPerOz` | `Double` | `0.0` | Cost per fluid ounce |
| `currentStockOz` | `Double` | `0.0` | Current stock level in ounces |
| `unitLabel` | `String` | `"oz"` | Display unit: "oz", "lbs", "gallons" |
| `concentration` | `Double` | `100.0` | Percentage (e.g., 31.45 for muriatic acid) |
| `lowStockThresholdOz` | `Double` | `0.0` | Threshold for low-stock alerts |

**Relationships:**
- `doses: [ChemicalDose]` -- nullify on delete, inverse `\ChemicalDose.chemical`

**Computed Properties:**
- `chemicalType: ChemicalType` -- getter/setter wrapping `chemicalTypeRaw`
- `isLowStock: Bool` -- true when `lowStockThresholdOz > 0 && currentStockOz < lowStockThresholdOz`

**ChemicalType Enum:** `acid`, `base`, `calcium`, `alkalinity`, `chlorine`, `stabilizer`, `dilution`, `none`

**Default Catalog (seeded on first launch when inventory is empty):**

| Chemical | Type | Cost/oz | Initial Stock (oz) | Concentration |
|---|---|---|---|---|
| Muriatic Acid (31.45%) | acid | $0.05 | 256 (2 gal) | 31.45% |
| Soda Ash (Sodium Carbonate) | base | $0.09 | 160 (10 lbs) | 100% |
| Calcium Chloride (Hardness Up) | calcium | $0.07 | 400 (25 lbs) | 77% |
| Sodium Bicarbonate (Alkalinity Up) | alkalinity | $0.04 | 320 (20 lbs) | 100% |
| Trichlor Tabs (Stabilized Chlorine) | chlorine | $0.18 | 400 (25 lbs) | 90% |
| Liquid Chlorine (12.5% Sodium Hypochlorite) | chlorine | $0.02 | 512 (4 gal) | 12.5% |
| Cyanuric Acid (Stabilizer) | stabilizer | $0.12 | 64 (4 lbs) | 100% |

---

### Equipment (`@Model`)

Tracks a piece of equipment installed at a customer's pool. Stores warranty and service dates for proactive maintenance alerts.

| Property | Type | Default | Notes |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Primary key |
| `name` | `String` | `""` | Equipment name |
| `equipmentTypeRaw` | `String` | `"other"` | Stored enum raw value |
| `manufacturer` | `String` | `""` | |
| `modelNumber` | `String` | `""` | |
| `serialNumber` | `String` | `""` | |
| `installDate` | `Date?` | `nil` | |
| `warrantyExpiryDate` | `Date?` | `nil` | |
| `lastServiceDate` | `Date?` | `nil` | |
| `nextServiceDate` | `Date?` | `nil` | |
| `notes` | `String` | `""` | |
| `createdAt` | `Date` | `Date()` | |
| `updatedAt` | `Date` | `Date()` | |
| `pool` | `Pool?` | `nil` | Inverse of `Pool.equipment` |

**Computed Properties:**
- `equipmentType: EquipmentType` -- getter/setter wrapping `equipmentTypeRaw`
- `isWarrantyExpired: Bool` -- true when `warrantyExpiryDate < Date()`
- `isServiceOverdue: Bool` -- true when `nextServiceDate < Date()`

**EquipmentType Enum:** `pump`, `filter`, `heater`, `cleaner`, `saltSystem`, `automation`, `light`, `cover`, `other`

---

### CustomerProfileData (UserDefaults, JSON-encoded)

Stored per pool via `CustomerProfileViewModel` with key prefix `customerProfile.<poolID>`. Not a SwiftData model -- lives in `UserDefaults` for lightweight access.

| Property | Type | Notes |
|---|---|---|
| `contactName` | `String` | Customer contact name |
| `contactPhone` | `String` | Phone number |
| `contactEmail` | `String` | Email address |
| `gateAccessType` | `String` | Gate/access instructions |
| `preferredArrivalWindow` | `String` | Preferred service time window |
| `tagsCSV` | `String` | Comma-separated tags (e.g., "residential,heated") |

---

### WaterChemistryDefaults (Enum)

Single source of truth for default water chemistry values used across `Pool.init()`, `ServiceEvent.init()`, `DosingViewModel`, and `QuickLogView`:

| Parameter | Default | Unit |
|---|---|---|
| pH | 7.4 | -- |
| Water Temperature | 78.0 | degF |
| Calcium Hardness | 250.0 | ppm |
| Total Alkalinity | 100.0 | ppm |
| Total Dissolved Solids | 1,000.0 | ppm |
| Cyanuric Acid | 30.0 | ppm |
| Pool Volume | 15,000.0 | gallons |
| Monthly Service Fee | 150.0 | USD |

**Region-Aware Defaults:** Pool volume and temperature are adjusted based on the user's locale region:
- US/CA: 15,000 gal, 78 degF
- GB/DE: 13,209 gal (~50,000 L), 77 degF
- AU/FR: 13,209 gal, 79 degF
- ES/BR: 13,209 gal, 82 degF

---

### SwiftData Schema

Defined in `PoolFlowApp.swift`:

```swift
private static let schema = Schema([Pool.self, ServiceEvent.self, ChemicalDose.self, ChemicalInventory.self, Equipment.self])
```

**Schema Versioning (`SchemaVersioning.swift`):**
- `PoolFlowSchemaV1` -- v1.0.0: `Pool`, `ServiceEvent`, `ChemicalDose`, `ChemicalInventory`
- `PoolFlowSchemaV2` -- v2.0.0: Same models (lightweight migration from V1)
- `PoolFlowMigrationPlan` -- `.lightweight(fromVersion: V1, toVersion: V2)`
- Note: The earlier codebase revision used `Schema(versionedSchema: PoolFlowSchemaV2.self)` with `PoolFlowMigrationPlan`; the current entry point uses a direct `Schema([...])` initializer with all five model types.

**ModelConfiguration:**
- `isStoredInMemoryOnly: false`
- `cloudKitDatabase`: `.automatic` for Pro users, `.none` for free tier
- External storage enabled for `ServiceEvent.photoData`

---

## 5. Third-Party Integrations

### 5.1 RevenueCat -- Subscription Management

**SDK:** `purchases-ios-spm` v5.59.2

**Configuration:**
- API key loaded at runtime from `Info.plist` via the `RevenueCatAPIKey` entry, which resolves to `$(REVENUECAT_API_KEY)` from xcconfig files.
- Configured once in `PoolFlowApp.init()` via `SubscriptionManager.shared.configureIfNeeded(apiKey:)`.
- Debug builds enable `Purchases.logLevel = .debug`.

**Entitlement:** `"pro"` (single entitlement gating all premium features)

**Product IDs:**

| Product ID | Price | Period | Trial |
|---|---|---|---|
| `poolflow_pro_monthly` | $19.99 | Monthly | 1-week free |
| `poolflow_pro_annual` | $149.99 | Annual | 1-week free |

- Subscription group: `poolflow_pro` (group ID: `POOLFLOW_PRO_GROUP`)

**Free Tier Cap:** 5 pools (`SubscriptionManager.freePoolCap`)

**Premium Features (`PremiumFeature` enum):**
- `.analytics` -- Profit dashboard / analytics tab
- `.routeOptimization` -- Route optimization engine
- `.backupRestore` -- Full backup and restore
- `.unlimitedPools` -- More than 5 pools

**Paywall Contexts (`PaywallContext` enum):**
- `.analyticsTab` -- "Unlock Analytics"
- `.optimizeRoute` -- "Unlock Route Optimization"
- `.backupRestore` -- "Unlock Full Backup & Restore"
- `.poolCapReached` -- "Upgrade for Unlimited Pools"
- `.settingsUpgrade` -- "Upgrade to PoolFlow Pro"
- `.cloudSync` -- "Unlock iCloud Sync"

**Subscription Tiers:** `free`, `trial`, `paid`

**Fallback Behavior:** If the RevenueCat API key is missing or SDK fails to initialize, the app runs in free-tier fallback mode with `billingUnavailableMessage` set. The app remains fully functional at free-tier capabilities.

**UI Test Support:** Launch arguments enable deterministic testing without live billing:
- `-uiTestSubscriptionTier=free|trial|paid` -- override subscription state
- `-uiTestUseStubPaywall` -- use a stub paywall instead of RevenueCat

---

### 5.2 CloudKit -- Cross-Device Data Sync

**Entitlements (`PoolFlow.entitlements`):**
- Service: `CloudKit`
- Container: `iCloud.com.poolflow.app`

**Implementation:**
- CloudKit sync is enabled **only for Pro subscribers**. The `ModelConfiguration` is created with `cloudKitDatabase: isProUser ? .automatic : .none`.
- `CloudSyncMonitor` (`@Observable`) checks `CKContainer.default().accountStatus()` on app launch and observes `NSPersistentCloudKitContainer.eventChangedNotification` for sync status updates.
- Sync status states: `idle`, `syncing`, `synced(Date)`, `error(String)`, `accountUnavailable`.

---

### 5.3 MapKit -- Routing, ETA & Address Autocomplete

**Three components use MapKit:**

1. **`HybridTravelTimeEstimator` (Swift actor):**
   - Primary: `MKDirections.calculateETA()` for automobile travel time between coordinates.
   - Fallback: Haversine-distance approximation at 28 MPH average with 1.5-minute stop/start overhead.
   - Results cached in-memory by coordinate pair key.

2. **`RouteOptimizationEngine` (`@MainActor`):**
   - Algorithm: Nearest-neighbor seed + 2-opt local improvement (max 2 passes).
   - Three optimization objectives: `minDriveTime`, `minDriveDistance`, `balanced` (includes displacement penalty of 0.6x per position).
   - Produces `RouteOptimizationResult` comparing current vs. optimized stop ordering and estimated minutes saved.
   - Pools with coordinates `(0.0, 0.0)` are treated as unresolved and excluded from optimization.

3. **`AddressSearchCompleter` (`@Observable`):**
   - Wraps `MKLocalSearchCompleter` with 250ms debounce and minimum 3-character query threshold.
   - Result types filtered to `.address` only.
   - `resolve(_:)` method uses `MKLocalSearch` to geocode a completion into full address string + latitude/longitude coordinates.

---

### 5.4 StoreKit -- App Store Review Prompts

**`AppReviewManager` (static enum):**
- Uses `SKStoreReviewController.requestReview(in:)` for smart review prompts.
- Triggers: quick-log milestones (5, 15, 50 logs) and first route completion.
- Guardrails: maximum 1 prompt per app version, minimum 60 days between prompts.
- State persisted via `AppStorageKey.lastReviewRequestDate`, `.reviewRequestCount`, `.reviewRequestAppVersion`.

**Sandbox StoreKit Configuration (`PoolFlow.storekit`):**
- Configured in the Xcode scheme for both Run (`LaunchAction`) and Test (`TestAction`) actions.
- Enables sandbox-safe subscription testing without App Store Connect.
- `_failTransactionsEnabled` defaults to `false` (can be toggled for failure simulation).

---

### 5.5 ZIPFoundation -- Backup & Restore

**SDK:** v0.9.20

**Full Backup Export (`DataExportService.exportFullBackup`):**
- Creates a temporary directory tree with JSON files for each entity type plus a `media/service-events/` folder for photo data.
- Archive structure:

```
full-backup-{timestamp}.zip/
  manifest.json            -- Schema version, timestamp, app version, entity counts
  pools.json               -- All Pool records
  service_events.json      -- All ServiceEvent records (photo data stored separately)
  chemical_doses.json      -- All ChemicalDose records
  inventory.json           -- All ChemicalInventory records
  customer_profiles.json   -- All CustomerProfileRecord entries
  equipment.json           -- All Equipment records
  media/
    service-events/
      {event-uuid}.bin     -- JPEG photo data per service event
```

- Compresses via `FileManager.zipItem(at:to:shouldKeepParent: false)`.
- JSON encoding uses `.prettyPrinted`, `.sortedKeys`, `.iso8601` date strategy.

**Full Backup Restore (`DataImportService.applyFullBackup`):**
- Extracts archive via `FileManager.unzipItem(at:to:)`.
- Validates manifest schema version compatibility (min: 1, max: 2).
- Validates all referential integrity: service events reference valid pools, doses reference valid events and chemicals.
- **Destructive restore:** deletes all existing data before inserting backup records.
- Equipment records are optional (not present in v1 backups, gracefully skipped).

**Schema Versioning:**

| Version | Changes |
|---|---|
| 1 | Initial: pools, service events, chemical doses, inventory, customer profiles, media |
| 2 | Added `equipment.json` (backward-compatible: optional on import) |

---

## 6. Security & Configuration

### API Key Management

- **RevenueCat API Key** is **never hardcoded** in Swift source files. It flows through the build configuration:
  - `Config/Debug.xcconfig` -- contains sandbox/test API key for development.
  - `Config/Release.xcconfig` -- placeholder for production key (`REVENUECAT_API_KEY =`), must be set before App Store submission.
  - The xcconfig value is interpolated into `Info.plist` via `$(REVENUECAT_API_KEY)`.
  - At runtime, `PoolFlowApp.init()` reads it with `Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey")`.

### CloudKit Entitlements

- **File:** `PoolFlow.entitlements`
- **iCloud Services:** CloudKit
- **Container Identifier:** `iCloud.com.poolflow.app`
- CloudKit is **conditionally enabled at runtime** based on subscription status -- free-tier users operate in local-only mode (`cloudKitDatabase: .none`).

### StoreKit Sandbox Testing

- The Xcode scheme references `PoolFlow.storekit` for both `LaunchAction` and `TestAction`, enabling sandbox StoreKit testing without App Store Connect.
- Products: `poolflow_pro_monthly` ($19.99/mo), `poolflow_pro_annual` ($149.99/yr).
- Transaction failure simulation toggleable via `_failTransactionsEnabled` (default: `false`).

### Data Privacy

| Aspect | Implementation |
|---|---|
| Data at rest | iOS device encryption (hardware-level, transparent) |
| Network calls | RevenueCat (subscriptions), CloudKit (Pro sync), MapKit (ETA/search) only |
| Analytics/telemetry | **None** -- no third-party tracking |
| Authentication | **None** -- no login/user accounts |
| Photo storage | `@Attribute(.externalStorage)` -- inherits device encryption |
| Customer profiles | `UserDefaults` (device-local, not synced to iCloud) |
| Backup archives | Unencrypted ZIP files -- contain full customer data if exported |
| Data export | User-initiated only (CSV, PDF, ZIP) via system share sheet |

### Data Store Recovery

The app implements a robust 3-tier store-recovery flow via `StoreStartupState`:

1. **`.loading`** -- Attempt to open `ModelContainer` on launch.
   - Success: transition to `.ready(ModelContainer)`.
   - Failure: transition to `.recovery(StoreFailureContext)`.
2. **`.recovery`** -- Present `StoreRecoveryView` with three options:
   - **Retry** -- attempt to reopen the store.
   - **Reset Local Database** -- deletes all `.sqlite`, `.sqlite-wal`, and `.sqlite-shm` files and creates a fresh store with default inventory seeded.
   - **Restore from Backup** -- imports a user-selected `.zip` backup archive via `DataImportService.applyFullBackup`.

---

## 7. Build & Deployment

### Minimum Deployment Target

- **iOS 17.6** (app target: `IPHONEOS_DEPLOYMENT_TARGET = 17.6`)

### Target Devices

- **iPhone and iPad** (`TARGETED_DEVICE_FAMILY = "1,2"`)
- iPad uses `NavigationSplitView` with sidebar; iPhone uses `TabView`.
- Adaptive layouts via `@Environment(\.horizontalSizeClass)` and `Theme.Adaptive`:
  - Grid columns: 3 (regular/iPad), 2 (compact/iPhone)
  - Chart height: 280pt (iPad), 200pt (iPhone)
  - Photo thumbnails: 120pt (iPad), 80pt (iPhone)
  - Max content width: 700pt

### Supported Orientations

| Device | Orientations |
|---|---|
| iPhone | Portrait, Landscape Left, Landscape Right |
| iPad | All four (including Portrait Upside Down) |

### Multi-Scene Support

- `UIApplicationSupportsMultipleScenes = true` in `Info.plist`, enabling iPad Split View and Stage Manager multitasking.

### Build Configurations

| Configuration | Purpose | RevenueCat Key Source |
|---|---|---|
| **Debug** | Development, testing, sandbox | `Config/Debug.xcconfig` (sandbox key included) |
| **Release** | App Store / TestFlight builds | `Config/Release.xcconfig` (production key placeholder) |

### Xcode Scheme: `PoolFlow` (shared)

| Action | Configuration | Notes |
|---|---|---|
| Build | Automatic | Parallel builds, implicit dependencies |
| Run | Debug | StoreKit sandbox config attached |
| Test | Debug | Parallel test targets; StoreKit sandbox config attached |
| Profile | Release | Instruments profiling |
| Archive | Release | App Store distribution |

### Test Targets

| Target | Type | Test Files |
|---|---|---|
| `PoolFlowTests` | Unit | `DosingEngineTests`, `DosingViewModelTests`, `LSICalculatorTests`, `LSIStatusContentTests`, `RouteOptimizationEngineTests`, `NotificationManagerScheduleTests`, `FullBackupServiceTests`, `AddressSearchCompleterStateTests`, `ThemeTests`, `CloudSyncMonitorTests`, `OnboardingFlowViewModelTests`, `DataImportServiceParsingTests`, `LocalizationCurrencyTests`, `LocalizationCatalogTests`, `LocalizationRuntimeLookupTests`, `DosingInstructionLocalizationTests` |
| `PoolFlowUITests` | UI | `PoolFlowUITests`, `PoolFlowUITestsLaunchTests` |

---

### Project Structure

```
PoolFlow/
  App/
    PoolFlowApp.swift              -- @main, 5-model schema, StoreStartupState, RevenueCat init, CloudKit conditional, store recovery
    AppPreferences.swift           -- AppStorageKey constants (~45 keys), OnboardingCompletionIntent, SettingsPendingImportLaunchMode, NotificationScenarioSelection
    AppServices.swift              -- @MainActor @Observable dependency container (SubscriptionManager, NotificationManager, DataImportService, etc.)
    AppLocaleResolver.swift        -- Locale resolution, language override, currency-safe locale, AppFormatters
    AppStrings.swift               -- Runtime string localization with bundle resolution for language overrides
    Theme.swift                    -- Visual constants, colors, haptics, adaptive layout, accessibility
    UnitSystem.swift               -- UnitSystemPreference enum, UnitManager @Observable
  Config/
    Debug.xcconfig                 -- Debug build settings (RevenueCat sandbox key)
    Release.xcconfig               -- Release build settings (production key placeholder)
  Engine/
    LSICalculator.swift            -- Langelier Saturation Index formula with interpolation tables
    DosingEngine.swift             -- Chemical dosing recommendations from LSI deviations
    DosingFormatter.swift          -- Unit-aware quantity and instruction formatting
  Models/
    Pool.swift                     -- @Model: core pool entity
    ServiceEvent.swift             -- @Model: service visit + ChemicalDose @Model
    ChemicalInventory.swift        -- @Model: chemical products + ChemicalType enum
    Equipment.swift                -- @Model: pool equipment + EquipmentType enum
    WaterChemistryDefaults.swift   -- Default values and region-aware presets
    SchemaVersioning.swift         -- PoolFlowSchemaV1/V2, PoolFlowMigrationPlan (lightweight migration)
  ViewModels/
    SubscriptionManager.swift      -- RevenueCat, entitlements, paywall logic
    CloudSyncMonitor.swift         -- iCloud account status and sync monitoring
    DosingViewModel.swift          -- LSI/dosing calculator state, ServiceEvent creation
    PoolListViewModel.swift        -- Day filtering, route reordering
    RouteOptimizationEngine.swift  -- Nearest-neighbor + 2-opt route optimization
    TravelTimeEstimator.swift      -- MapKit ETA with haversine fallback (actor)
    AddressSearchCompleter.swift   -- MKLocalSearchCompleter wrapper with debounce
    CustomerProfileViewModel.swift -- UserDefaults-based customer profile CRUD
    NotificationManager.swift      -- Local notification scheduling
    AppReviewManager.swift         -- SKStoreReviewController prompts
    DataExportService.swift        -- CSV, PDF, ZIP export
    DataImportService.swift        -- CSV import with upsert, full backup restore
    FullBackupModels.swift         -- Codable backup records, manifest, schema versioning
    BackupCodec.swift              -- BackupCodec protocol + ZIPBackupCodec actor (ZIP archive creation/extraction)
    PDFReportRenderer.swift        -- UIGraphicsPDFRenderer for visit/performance reports
    OnboardingFlowViewModel.swift  -- Multi-step onboarding with profiling and branching
    OnboardingGuideManager.swift   -- Post-onboarding contextual tooltips
  Views/
    PoolListView.swift             -- Today's route with day picker
    PoolDetailView.swift           -- Pool detail with readings, history, equipment
    AddPoolView.swift              -- New pool creation form
    EditPoolView.swift             -- Pool editing form
    PoolFormFields.swift           -- Shared pool form field components
    QuickLogView.swift             -- Fast service logging with photo capture
    DosingCalculatorView.swift     -- Interactive LSI calculator with sliders
    ServiceHistoryView.swift       -- Service event timeline
    EditServiceEventView.swift     -- Service event editing
    ProfitDashboardView.swift      -- Analytics/profit dashboard (Pro)
    SettingsView.swift             -- App settings, import/export, subscription management
    EquipmentListView.swift        -- Equipment management per pool
    EditEquipmentView.swift        -- Equipment editing form
    EditInventoryItemView.swift    -- Chemical inventory editing
    ChemicalUsageHistoryView.swift -- Chemical usage over time
    SubscriptionPaywallSheet.swift -- Paywall presentation
    StoreRecoveryView.swift        -- Database recovery UI
    ReadingInputComponent.swift    -- Reusable chemistry reading input
    ActivityShareSheet.swift       -- UIActivityViewController wrapper
    MailComposeView.swift          -- MFMailComposeViewController wrapper
    OnboardingView.swift           -- Legacy onboarding view
    Onboarding/
      OnboardingFlowView.swift
      OnboardingWelcomeStep.swift
      OnboardingProfilingStep.swift
      OnboardingFeatureHighlightsStep.swift
      OnboardingGuidedActionStep.swift
      OnboardingImportMethodStep.swift -- Import method chooser (CSV/backup/manual/skip) for migrating users
      OnboardingInlineAddPoolView.swift
      OnboardingQuestionCard.swift
    Guide/
      OnboardingGuideOverlay.swift
      ContextualTooltipView.swift
  StoreKit/
    PoolFlow.storekit              -- Sandbox StoreKit configuration
  Assets.xcassets/                 -- App icon (1024x1024), accent color
  Info.plist                       -- App configuration
  PoolFlow.entitlements            -- CloudKit entitlements
  Localizable.xcstrings            -- String catalog for localization
```

---

### Engine Layer Detail

#### LSICalculator

The Langelier Saturation Index calculator implements the standard industry formula:

```
LSI = pH + TF + CF + AF - TDS_Constant
```

Where:
- **TF** = Temperature Factor (from lookup table, interpolated)
- **CF** = Calcium Hardness Factor (from lookup table, interpolated)
- **AF** = Alkalinity Factor (from lookup table, interpolated, with CYA correction)
- **TDS_Constant** = Total Dissolved Solids correction (default 12.10 for 1000 ppm)

**CYA Correction:** Adjusted alkalinity = `max(0, totalAlkalinity - (cyanuricAcid / 3.0))`

**Status Thresholds:**
- LSI < -0.3: **Corrosive** -- water dissolves plaster, corrodes equipment, etches surfaces
- LSI -0.3 to +0.3: **Balanced** -- no significant scaling or corrosion tendency
- LSI > +0.3: **Scale-Forming** -- calcium deposits, cloudy water, clogged heaters

All lookup tables use linear interpolation for values between entries. Values below/above table range are clamped to first/last factor.

#### DosingEngine

Translates LSI deviations into specific, actionable chemical dosing recommendations:

- **Priority:** pH adjustment is always step 1 (fastest-acting, most impactful).
- **Corrosive water (LSI < -0.3):**
  1. Raise pH with Soda Ash (6 oz / 10k gal / 0.2 pH increment)
  2. Raise TA with Sodium Bicarbonate (24 oz / 10k gal / 10 ppm)
  3. Raise CH with Calcium Chloride (20 oz / 10k gal / 10 ppm)
- **Scale-forming water (LSI > +0.3):**
  1. Lower pH with Muriatic Acid (26 oz / 10k gal / 0.2 pH increment)
  2. Lower TA with acid + aeration note
  3. Partial drain & refill for extreme calcium (> 400 ppm)
- **Fallback nudge:** If no specific parameter is out of range but LSI is still off, provides a small pH nudge.
- **Cost estimation:** Uses actual inventory costs via `CostLookup`, falling back to industry-average defaults.
- **Profit analysis:** `profitAnalysis()` compares monthly service fee against chemical spend over a configurable billing period.

---

### Design System (`Theme.swift`)

#### Touch Targets (Glove-Friendly)

| Constant | Value | Purpose |
|---|---|---|
| `minTouchTarget` | 44 pt | Accessibility minimum |
| `buttonHeight` | 56 pt | Primary action buttons |
| `cornerRadius` | 14 pt | Standard rounded corners |
| `cardCornerRadius` | 16 pt | Card containers |
| `tileCornerRadius` | 12 pt | Dashboard tiles |

#### LSI Status Colors & Haptics

| Water Condition | Color | Haptic |
|---|---|---|
| Corrosive (LSI < -0.3) | Blue | Error |
| Balanced (-0.3 to +0.3) | Green | Success |
| Scale-Forming (LSI > +0.3) | Orange | Warning |

#### Chemical Type Colors

| Type | Color |
|---|---|
| Acid | Red |
| Base | Blue |
| Calcium | Cyan |
| Alkalinity | Teal |
| Chlorine | Yellow |
| Stabilizer | Indigo |
| Dilution | Orange |
| None | Gray |

#### Adaptive Layout

| Trait | iPhone (compact) | iPad (regular) |
|---|---|---|
| Navigation | TabView (4 tabs) | NavigationSplitView (sidebar) |
| Grid columns | 2 | 3 |
| Chart height | 200 pt | 280 pt |
| Photo thumbnail | 80 pt | 120 pt |
| Max content width | -- | 700 pt |

---

### Notification System

Four notification scenarios managed by `NotificationManager`:

| Scenario | Trigger | Schedule |
|---|---|---|
| **Morning Route Summary** | Pools scheduled for today | Configurable time (default 7:00 AM), repeating on route days |
| **Low Stock for Tomorrow** | Low-stock chemicals + pools scheduled tomorrow | 6:30 PM daily (suppressed when morning summary is enabled) |
| **Weekly Digest** | Always (if enabled) | Sunday 5:00 PM |
| **Trial Expiring** | Pro trial detected | One-time, 1 day before expiration |

**Smart Prompt:** Notification permission is requested only after the user has completed 3 quick logs or 1 full route, avoiding premature interruption.

---

### Onboarding System

**Multi-step interactive onboarding (`OnboardingFlowViewModel`):**

| Step | Content |
|---|---|
| 1. Welcome | App introduction |
| 2. User Type | Brand new / Migrating / Business owner |
| 3. Pool Count | Small / Medium / Large (skipped for brand-new users) |
| 4. Feature Focus | Route focus / Chemistry focus / Profit focus |
| 5. Feature Highlights | Personalized feature showcase |
| 6. Import Method | CSV import / Backup restore / Manual add / Skip (shown for migrating/business owner users via `OnboardingImportMethodStep`) |
| 7. Guided Action | Add first pool (brand-new/small) or proceed to settings for import |

**Post-onboarding tooltips (`OnboardingGuideManager`):**
- `routeIntro` -- Route tab introduction
- `quickLogIntro` -- Quick log discovery
- `lsiDiscovery` -- LSI calculator after first quick log
- `analyticsTeaser` -- Analytics tab after 3 quick logs

Each tooltip shows exactly once, tracked via `AppStorage` flags.

---

*This document describes the complete technical foundation of PoolFlow as of the current codebase. For feature details, see [03_Feature_Inventory](03_Feature_Inventory.md). For behavioral specifications, see [04_Functional_Scope](04_Functional_Scope.md). For user journey maps, see [05_Customer_Journeys](05_Customer_Journeys.md).*
