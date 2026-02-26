# PoolFlow -- Complete Feature Inventory

> **Document:** 03_Feature_Inventory
> **Version:** 2.1
> **Last Updated:** 2026-02-25
> **Related Docs:** [01_App_Blueprint](01_App_Blueprint.md) | [02_Product_Strategy](02_Product_Strategy.md) | [04_Functional_Scope](04_Functional_Scope.md) | [05_Customer_Journeys](05_Customer_Journeys.md)

---

## Feature Groups Overview

| # | Group | Feature Count | Primary Source Files |
|---|-------|:------------:|----------------------|
| 1 | Route Management | 12 | `PoolListView.swift`, `PoolListViewModel.swift`, `RouteOptimizationEngine.swift`, `TravelTimeEstimator.swift` |
| 2 | Water Chemistry & Dosing | 14 | `LSICalculator.swift`, `DosingEngine.swift`, `DosingFormatter.swift`, `DosingViewModel.swift`, `DosingCalculatorView.swift`, `ReadingInputComponent.swift` |
| 3 | Service Logging (Quick Log) | 10 | `QuickLogView.swift` |
| 4 | Profit Analytics | 6 | `ProfitDashboardView.swift`, `DosingEngine.swift` |
| 5 | Equipment Tracking | 5 | `Equipment.swift`, `EquipmentListView.swift`, `EditEquipmentView.swift` |
| 6 | Data Management | 12 | `DataExportService.swift`, `DataImportService.swift`, `PDFReportRenderer.swift`, `FullBackupModels.swift`, `BackupCodec.swift`, `MailComposeView.swift` |
| 7 | Subscription & Monetization | 9 | `SubscriptionManager.swift`, `SubscriptionPaywallSheet.swift` |
| 8 | Onboarding & Guided Setup | 11 | `OnboardingFlowView.swift`, `OnboardingFlowViewModel.swift`, `OnboardingWelcomeStep.swift`, `OnboardingProfilingStep.swift`, `OnboardingQuestionCard.swift`, `OnboardingFeatureHighlightsStep.swift`, `OnboardingGuidedActionStep.swift`, `OnboardingInlineAddPoolView.swift`, `OnboardingImportMethodStep.swift`, `OnboardingView.swift`, `OnboardingGuideManager.swift`, `ContextualTooltipView.swift` |
| 9 | Notifications | 5 | `NotificationManager.swift`, `PoolFlowApp.swift` |
| 10 | Settings & Preferences | 14 | `SettingsView.swift`, `AppPreferences.swift`, `UnitSystem.swift`, `Theme.swift` |
| 11 | Localization & Units | 6 | `UnitSystem.swift`, `DosingFormatter.swift`, `WaterChemistryDefaults.swift`, `Localizable.xcstrings` |
| 12 | Platform, Layout & UX Polish | 10 | `PoolFlowApp.swift`, `Theme.swift`, `StoreRecoveryView.swift`, `AppReviewManager.swift`, `CloudSyncMonitor.swift`, `AppServices.swift`, `AppStrings.swift`, `AppLocaleResolver.swift` |
| | **Total** | **114** | |

---

## 1. Route Management

### 1.1 Day-of-Week Route Filtering
- **Screen:** `PoolListView` -- "Today's Route" tab
- **Behavior:** Horizontal day picker across the top of the route list; each button shows the localized weekday name and the count of pools assigned to that day (e.g., "Mon 6")
- **Default:** Automatically selects today's weekday on first appearance
- **Source:** `PoolListViewModel.selectedDayOfWeek` (defaults to `Calendar.current.component(.weekday, from: Date())`)
- **Localization:** Weekday names are derived from `Calendar.current.weekdaySymbols` and respect the user's locale

### 1.2 Route Progress Tracking
- **Screen:** `PoolListView` -- progress bar below the day picker
- **Display:** "X of Y serviced" with a green progress bar
- **Calculation:** Counts pools for the selected day that have at least one `ServiceEvent` with today's date
- **Badge:** The "Today's Route" tab icon shows a badge with the number of unserviced pools for today (`unservicedTodayCount`)

### 1.3 Drag-and-Drop Route Reordering
- **Screen:** `PoolListView` -- pool list
- **Behavior:** Long-press and drag to reorder pools within a day's route; updates `Pool.routeOrder` on all affected items and persists immediately via `modelContext.save()`
- **Source:** `PoolListViewModel.movePool(from:to:pools:modelContext:)`

### 1.4 Route Optimization Engine
- **Screen:** `PoolListView` -- wand button in the toolbar
- **Algorithm:** Nearest-neighbor seeding followed by 2-opt improvement (maximum 2 passes)
- **Objectives:** Three modes selectable in Settings:
  - **Minimize Drive Time** (`minDriveTime`) -- optimizes for lowest total ETA
  - **Minimize Drive Distance** (`minDriveDistance`) -- optimizes for shortest total haversine distance
  - **Balanced** -- weighted combination with displacement penalty to avoid drastic reordering
- **Minimum:** Requires 3 or more pools with valid coordinates (lat/lon != 0); pools without coordinates are flagged as "unresolved stops"
- **Source:** `RouteOptimizationEngine.swift`
- **Premium:** Requires Pro subscription

### 1.5 Route Optimization Preview Sheet
- **Screen:** `PoolListView` -- presented after tapping the optimize wand
- **Display:** Side-by-side comparison:
  - Current estimated route time (minutes)
  - Optimized estimated route time (minutes)
  - Estimated time saved
  - Number of unresolved stops (if any)
- **Actions:** "Apply" (reorders the route) or "Cancel"

### 1.6 Undo Route Optimization
- **Screen:** `PoolListView` -- toast after applying optimization
- **Behavior:** A toast notification allows the user to undo the applied optimization, reverting all `routeOrder` values to their pre-optimization state
- **Duration:** Toast remains visible until dismissed

### 1.7 One-Tap Apple Maps Directions
- **Screen:** `PoolListView` -- directions button per pool row; also available in `PoolDetailView`
- **Behavior:** Opens Apple Maps with driving directions to the pool's location
- **Primary:** Uses pool coordinates (`CLLocationCoordinate2D`) when available
- **Fallback:** Uses address string when coordinates are missing
- **Source:** `MKMapItem` with `launchOptions` for driving directions

### 1.8 Pool Search and Filtering
- **Screen:** `PoolListView` -- search bar (`.searchable` modifier)
- **Fields:** Searches across customer name, address, and notes (case-insensitive)
- **Behavior:** Filters the current day's pool list in real-time as the user types

### 1.9 Context Menu Actions
- **Screen:** `PoolListView` -- long-press on any pool row
- **Actions:**
  - "Quick Log" -- opens QuickLogView for that pool
  - "Get Directions" -- opens Apple Maps
  - "Delete Pool" -- triggers deletion confirmation

### 1.10 Swipe Actions
- **Screen:** `PoolListView` -- swipe on any pool row
- **Leading swipe (green):** "Complete" -- opens QuickLogView
- **Trailing swipe (red):** "Delete" -- triggers deletion confirmation

### 1.11 Route Completion Celebration
- **Screen:** `PoolListView` -- full-screen overlay
- **Trigger:** All pools for the selected day have been serviced (100% route progress)
- **Display:** Animated celebration overlay; sets `hasCompletedRouteOnce = true` (triggers app review eligibility and notification prompt eligibility)

### 1.12 Travel Time Estimation
- **Engine:** `TravelTimeEstimator` (Swift actor)
- **Primary:** MapKit `MKDirections` API for accurate ETA
- **Fallback:** Haversine great-circle distance with 28 MPH average speed approximation
- **Caching:** Results are cached by coordinate pair to avoid redundant network calls
- **Usage:** Powers the route optimization engine and preview sheet time estimates

---

## 2. Water Chemistry & Dosing

### 2.1 LSI Calculator Engine
- **Description:** Full Langelier Saturation Index calculation with real-time updates
- **Formula:** `LSI = pH + TF + CF + AF - TDS_Constant`
- **Implementation:** Stateless, pure-function design in `LSICalculator.swift`
- **Cyanuric Acid Adjustment:** `adjustedAlkalinity = max(0, totalAlkalinity - (cyanuricAcid / 3.0))`
- **Return Type:** `LSIResult` containing `lsiValue`, `temperatureFactor`, `calciumFactor`, `alkalinityFactor`, `tdsConstant`, and `waterCondition`

### 2.2 Lookup Table Interpolation
- **Description:** Linear interpolation between defined points in industry-standard lookup tables
- **Tables:**
  - Temperature Factor (TF) -- maps water temperature in degrees F to a factor
  - Calcium Factor (CF) -- maps calcium hardness in ppm to a factor
  - Alkalinity Factor (AF) -- maps adjusted alkalinity in ppm to a factor
  - TDS Constant -- maps total dissolved solids in ppm to a constant
- **Behavior:** Values between table points are linearly interpolated; values outside bounds clamp to nearest endpoint

### 2.3 Water Condition Classification
- **Corrosive:** LSI < -0.3 (blue badge, error haptic)
- **Balanced:** LSI between -0.3 and +0.3 (green badge, success haptic)
- **Scale-Forming:** LSI > +0.3 (orange badge, warning haptic)
- **Localized Names:** `WaterCondition.localizedName(for:)` returns translated status strings

### 2.4 Five Chemistry Parameter Inputs
- **Parameters:** pH, Temperature, Calcium Hardness (ppm), Total Alkalinity (ppm), Cyanuric Acid (ppm)
- **Input Modes:**
  - **Slider mode** (`DosingCalculatorView`): Full-width row with label, value, minus/plus buttons, and slider. Tinted by parameter (pH = purple, Temp = red, Calcium = cyan, Alkalinity = teal, CYA = indigo)
  - **Compact mode** (`QuickLogView`): Tile layout with label, value, and minus/plus stepper buttons
- **Component:** `ReadingInputComponent.swift` -- shared reusable component
- **Haptics:** Light impact on each increment/decrement; error haptic at range bounds
- **Animation:** `.numericText` content transition on value changes

### 2.5 TDS and Pool Volume Inputs
- **TDS:** Total Dissolved Solids slider input (used in LSI TDS correction factor)
- **Pool Volume:** Used for dosing quantity calculations (chemicals dosed per 10,000 gallons); unit-aware (gallons or liters)

### 2.6 Ideal Range Status Indicators
- **pH:** 7.2--7.8 ideal (Low below 7.2, High above 7.8)
- **Calcium Hardness:** 200--400 ppm ideal
- **Total Alkalinity:** 80--120 ppm ideal
- **Temperature:** 60--90 degrees F ideal
- **CYA:** 30--100 ppm ideal
- **Visual:** Color-coded status badges -- blue (Low), green (Ideal), orange (High)
- **Source:** `Theme.pHStatus()`, `Theme.calciumStatus()`, `Theme.alkalinityStatus()`, `Theme.tempStatus()`, `Theme.cyaStatus()`

### 2.7 Prioritized Dosing Recommendations
- **Description:** Ordered list of chemical adjustments based on LSI deviation direction
- **Corrosive strategy (LSI < -0.3):**
  1. Raise pH with Soda Ash (target 7.4)
  2. Raise Total Alkalinity with Sodium Bicarbonate (target 80 ppm)
  3. Raise Calcium Hardness with Calcium Chloride (target 200 ppm)
- **Scale-forming strategy (LSI > 0.3):**
  1. Lower pH with Muriatic Acid (target 7.6)
  2. Lower Total Alkalinity with Muriatic Acid (target 120 ppm)
  3. Partial drain recommended if Calcium > 400 ppm (calcium cannot be chemically removed)
- **Balanced (LSI within range):** pH nudge toward 7.4 if deviation > 0.1
- **Source:** `DosingEngine.swift`

### 2.8 Cost Estimation from Inventory
- **Description:** Each recommendation includes an estimated cost based on the technician's actual chemical inventory
- **Matching:** `ChemicalInventory` items matched by `ChemicalType` to dosing recommendations
- **Fallback Costs (per oz):** Acid $0.05, Base $0.09, Calcium $0.07, Alkalinity $0.04, Chlorine $0.02, Stabilizer $0.12

### 2.9 Unit-Aware Dosing Formatter
- **Description:** Formats dosing quantities in the user's preferred unit system
- **Imperial:** Ounces (oz) for all chemicals; rounds up to nearest 1 oz
- **Metric:** Classifies chemicals as dry (base, alkalinity, calcium, stabilizer -> grams/kilograms) or liquid (acid, chlorine -> milliliters/liters)
- **Conversion Constants:** 1 oz = 28.3495 g (dry), 1 oz = 29.5735 mL (liquid)
- **Localized Instructions:** All instruction strings use `String(localized:)` for translation
- **Source:** `DosingFormatter.swift`

### 2.10 DosingCalculatorView (Full Calculator)
- **Screen:** "LSI Calculator" tab
- **Layout:** Hero LSI gauge (large format, animated) with status description, water reading sliders, pool parameter sliders, prioritized action step cards
- **Pool Context Mode:** When launched from a pool, pre-fills readings from that pool's latest service event; "Save" button writes updated readings back to the pool model and creates a ServiceEvent
- **Standalone Mode:** "Save to Pool..." button opens a pool picker sheet with search and sort modes (Today's Route, Most Recent Service, A-Z)
- **Haptic:** Status-specific haptic when LSI crosses a classification boundary

### 2.11 Chemistry Trend Charts
- **Screen:** `PoolDetailView` -- chemistry trend section
- **Framework:** Swift Charts
- **Data:** Last 15 service events, plotted chronologically
- **Series:** pH (line) and shifted LSI (line) on dual scale
- **Adaptive Height:** 200pt (iPhone) / 280pt (iPad)

### 2.12 Chemical Usage History View
- **Screen:** `ChemicalUsageHistoryView` -- navigated from `PoolDetailView` action buttons
- **Sections:**
  - **Usage Summary card:** Total spent, average cost per visit, total visits with chemical applications
  - **Top Chemicals card:** Top 5 chemicals ranked by total cost, with color-coded dots by chemical type, unit-aware quantity display, and currency amounts
  - **Cost Trend chart:** Bar chart of chemical costs per visit over time (requires 2+ visits)
  - **Visit Details:** Expandable list of every service event with chemical breakdowns (chemical name, quantity, cost)
- **Adaptive:** Uses `Theme.Adaptive.maxContentWidth` (700pt) for iPad layout

### 2.13 Profit Analysis per Pool
- **Description:** The `DosingEngine` also provides `profitAnalysis()` for per-pool financial calculations
- **Metrics:** Monthly fee (revenue), chemical cost over billing period, net profit, money loser flag
- **Money Loser Threshold:** Chemical cost > 30% of monthly service fee

### 2.14 Haptic Feedback on LSI Boundary Crossing
- **Trigger:** When the user adjusts a reading and the LSI classification crosses a boundary (e.g., corrosive to balanced)
- **Types:** Success haptic for balanced, warning haptic for scale-forming, error haptic for corrosive
- **Source:** `Theme.haptic(for:)` using pre-warmed `UINotificationFeedbackGenerator`

---

## 3. Service Logging (Quick Log)

### 3.1 Half-Sheet Quick Log Workflow
- **Screen:** `QuickLogView` -- presented as a half-sheet from `PoolListView`
- **Goal:** Complete a service log in under 2 minutes
- **Flow:** Review/adjust readings -> view live LSI and recommendations -> select chemicals applied -> optional photo -> optional notes -> confirm -> save

### 3.2 Pre-Filled Readings from Last Visit
- **Description:** All chemistry inputs are automatically populated from the pool's most recent `ServiceEvent`
- **Fallback:** Pool-level default readings if no prior service events exist
- **Source:** `Pool.latestReadings()` which prefers `serviceEvents.max(by: timestamp)` values, then falls back to pool model values

### 3.3 Live LSI Calculation
- **Description:** The LSI badge and water condition status update in real-time as the user adjusts any reading
- **Display:** LSI value with signed format (`+0.15` / `-0.42`), color-coded capsule badge

### 3.4 Chemical Dose Confirmation Checkboxes
- **Description:** Dosing recommendations are presented as toggle checkboxes; the technician selects which chemicals were actually applied
- **Auto-Select:** "Select All Recommendations" button available
- **Recorded:** Confirmed doses are saved as `ChemicalDose` entities linked to the `ServiceEvent`

### 3.5 Cost Summary
- **Description:** Running total of confirmed chemical costs displayed during the quick log
- **Source:** Sum of `(quantityOz * costPerOz)` for all selected chemicals

### 3.6 Proof-of-Service Photo
- **Description:** Optional photo captured via `PhotosPicker` (camera or library)
- **Processing:** Image downsampled to maximum 1200px on the longest dimension
- **Storage:** `ServiceEvent.photoData` with `@Attribute(.externalStorage)` -- stored as a binary file outside the SQLite database
- **Display:** Thumbnail preview in the quick log sheet; horizontal scroll gallery in `PoolDetailView`

### 3.7 Tech Notes Field
- **Description:** Free-text field for observations, issues, gate codes, follow-up reminders
- **Storage:** `ServiceEvent.techNotes`

### 3.8 Share Report
- **Description:** "Share" button generates a text-based service report and presents the system share sheet
- **Content:** Customer name, date, readings, LSI, chemicals applied, cost summary, tech notes

### 3.9 Five-Second Undo Toast
- **Description:** After saving, a toast notification appears for 5 seconds allowing the user to undo
- **Undo Behavior:** Removes the newly created `ServiceEvent`, reverses any inventory stock decrements
- **Purpose:** Error recovery for accidental or incorrect saves

### 3.10 Optional Save Confirmation Dialog
- **Toggle:** `quickLogConfirmBeforeSave` in Settings (default: off)
- **Behavior:** When enabled, a confirmation dialog ("Save this service log?") appears before the save is committed
- **Stock Decrement:** On save, `ChemicalInventory.currentStockOz` is reduced by the quantity of each confirmed chemical dose

---

## 4. Profit Analytics

### 4.1 Profit Dashboard
- **Screen:** `ProfitDashboardView` -- "Analytics" tab
- **Premium:** Requires Pro subscription; free users see a paywall
- **Summary Card:** Revenue (total monthly fees), Chemical Spend (total chemical costs in period), Net Profit
- **Money Loser Count:** Number of pools flagged as money losers

### 4.2 Billing Period Selection
- **Options:** 30 days (default), 60 days, 90 days
- **Behavior:** Filters service events to only include those within the selected lookback period

### 4.3 Per-Pool Breakdown Cards
- **Display:** Customer name, monthly service fee, chemical cost in period, net profit
- **Badge:** "MONEY LOSER" badge on pools where chemical cost > 30% of monthly fee
- **Color:** Profit-positive pools in green tones; money losers in red/orange tones
- **Actions per Card:**
  - "Open Detail" -- navigates to `PoolDetailView`
  - "Run Dosing" -- opens `DosingCalculatorView` pre-filled with that pool's readings
  - "Quick Log" -- opens `QuickLogView`

### 4.4 Sort Modes
- **Money Losers First** -- flagged pools sorted to the top
- **Worst Margin First** -- lowest profit percentage first
- **Highest Chem Spend** -- most expensive pools to service first
- **Alphabetical** -- by customer name A-Z

### 4.5 Money Loser Filter Toggle
- **Description:** Toggle to show only money-losing pools
- **Purpose:** Quick triage view for identifying problematic accounts that need fee adjustments or chemical strategy changes

### 4.6 Money Loser Detection
- **Threshold:** `totalChemCost > monthlyFee * 0.30`
- **Display:** "IN THE RED" badge in `PoolDetailView` profit card when chemical costs exceed the threshold
- **Analytics Context:** Subtitle in paywall reads "See money losers first and act faster with premium analytics."

---

## 5. Equipment Tracking

### 5.1 Equipment Model
- **9 Equipment Types:** Pump, Filter, Heater, Cleaner, Salt System, Automation, Light, Cover, Other
- **Fields:** Name, type, manufacturer, model number, serial number, install date, warranty expiry date, last service date, next service date, notes
- **Relationship:** Each equipment item belongs to one Pool (cascade delete)
- **Source:** `Equipment.swift`

### 5.2 Equipment List View
- **Screen:** `EquipmentListView` -- navigated from `PoolDetailView` "View All Equipment" link
- **Display:** Equipment name, type icon, manufacturer
- **Badges:**
  - "Warranty Expired" indicator when `warrantyExpiryDate < today`
  - "Service Overdue" indicator when `nextServiceDate < today`
- **Actions:** Add, edit (via sheet), delete (swipe or context menu)

### 5.3 Add / Edit Equipment
- **Screen:** `EditEquipmentView` -- presented as a sheet
- **Sections:**
  - Equipment Details: Name (required), Type picker (9 options), Manufacturer, Model Number, Serial Number
  - Dates: Optional toggles for Install Date, Warranty Expiry, Last Service Date, Next Service Date (each with a `DatePicker` when enabled)
  - Notes: Free-text field
- **Validation:** Name must not be empty
- **Haptic:** Success haptic on save

### 5.4 Equipment Preview in Pool Detail
- **Screen:** `PoolDetailView` -- equipment section
- **Display:** Shows up to 3 equipment items inline; "View All Equipment" link navigates to the full `EquipmentListView`

### 5.5 Equipment in Backup/Restore
- **Backup Schema:** `EquipmentBackupRecord` included in full ZIP backups (schema v2)
- **Backward Compatibility:** Equipment is optional in v1 backups (graceful handling when restoring older archives)

---

## 6. Data Management

### 6.1 CSV Export
- **Screen:** `SettingsView` -- "Data & Reports" section
- **Scopes:**
  - All Pools -- exports pool list with all fields
  - Service History -- exports all service events across all pools
  - Chemical Inventory -- exports current inventory with stock levels
  - Single Pool History -- exports service events for one specific pool (from `PoolDetailView`)
- **Format:** Comma-separated values with proper escaping (quoted fields containing commas/newlines)
- **Delivery:** System share sheet (`ActivityShareSheet`)

### 6.2 PDF Reports
- **Renderer:** `PDFReportRenderer.swift` using `UIGraphicsPDFRenderer`
- **Report Types:**
  - **Customer Visit Report** -- per-pool: customer info, most recent visit details (readings, LSI, chemicals, cost), pool snapshot, photo note
  - **Monthly Performance Report** -- business-wide: business snapshot (total revenue, total chem spend, net profit), money losers list (top 10)
- **Delivery:** System share sheet

### 6.3 Email Report to Customer
- **Screen:** `PoolDetailView` -- "Email Report to Customer" in the export toolbar menu
- **Implementation:** `MailComposeView` wrapping `MFMailComposeViewController`
- **Content:** Pre-filled subject line, recipient (from customer profile email), body text, PDF attachment
- **Requirement:** Device must have a configured mail account (`MFMailComposeViewController.canSendMail()`)

### 6.4 Full ZIP Backup Export
- **Screen:** `SettingsView` -- "Full Backup (.zip)" button
- **Contents:**
  - `manifest.json` -- schema version, export date, app version
  - `pools.json` -- all pool records
  - `service_events.json` -- all service event records
  - `chemical_doses.json` -- all chemical dose records
  - `inventory.json` -- all chemical inventory records
  - `customer_profiles.json` -- all customer profile records
  - `equipment.json` -- all equipment records (v2+)
  - `media/service-events/*.bin` -- proof-of-service photos
- **Schema Version:** 2 (minimum supported for restore: 1)
- **Premium:** Requires Pro subscription

### 6.5 Full Backup Restore
- **Screen:** `SettingsView` -- "Restore from Backup" button
- **Workflow:** Select ZIP file -> validate manifest -> preview entity counts -> confirmation dialog -> apply (replaces all local data)
- **Preview:** `FullBackupPreview` shows schema version, compatibility status, and counts for each entity type (pools, events, doses, inventory, profiles, equipment)
- **Compatibility:** Schema version check; v1 backups supported (equipment omitted); v2 fully supported
- **Reference Validation:** Verifies all foreign key references between entities before applying
- **Beta:** Gated behind `featureBackupRestoreEnabled` toggle in Settings
- **Premium:** Requires Pro subscription

### 6.6 CSV Customer Bulk Import
- **Screen:** `SettingsView` -- "Import Data (CSV)" button
- **Required Columns:** `customer_name`, `address`, `service_day`, `monthly_fee`, `pool_volume`, `notes`
- **Optional Columns:** `latitude`, `longitude`, `contact_name`, `contact_phone`, `tags`
- **Row Limit:** Maximum 5,000 rows
- **Preview Sheet:** Shows counts of creates, updates, skips, and issues before applying

### 6.7 Import UPSERT Merge Strategy
- **Match Key:** Normalized (lowercased, whitespace-collapsed) customer name + address
- **Create:** New pool for unmatched entries
- **Update:** Modifies service day, fee, volume, and coordinates for matched pools
- **Skip:** Rows that fail validation (missing required fields, invalid data)
- **Route Order:** New pools are assigned `routeOrder` after existing pools for their service day

### 6.8 Import Template Download
- **Screen:** `SettingsView` -- "Download Import Template" button
- **Content:** CSV file with column headers and sample data rows demonstrating the expected format
- **Delivery:** System share sheet

### 6.9 Clear All App Data
- **Screen:** `SettingsView` -- "Clear All Data" button (red, destructive)
- **Behavior:** Confirmation dialog -> deletes all SwiftData entities (pools, events, doses, inventory, equipment) and clears UserDefaults -> re-seeds default chemical catalog
- **Warning:** Irreversible; only recourse is backup restore

### 6.10 Three-Tier Startup Recovery
- **Screen:** `StoreRecoveryView` -- presented when the SwiftData store fails to open
- **States:** Loading -> Ready (normal) or Recovery (failure)
- **Recovery Options:**
  1. **Retry** -- attempt to reopen the persistent store
  2. **Reset Local Database** -- delete all store files (.sqlite, -wal, -shm) and create a fresh container
  3. **Restore from Backup** -- select a ZIP file, reset store, then apply the backup
- **Store Files Managed:** Main SQLite file plus WAL and SHM companion files

### 6.11 Activity Share Sheet
- **Component:** `ActivityShareSheet.swift` -- `UIActivityViewController` wrapper
- **Usage:** Presents the iOS system share sheet for CSV, PDF, and ZIP files throughout the app

### 6.12 Customer Profile Export/Import
- **Storage:** Per-pool customer profiles stored in UserDefaults (keyed by pool UUID)
- **Fields:** Contact name, phone, email, gate access type, preferred arrival window, tags (CSV)
- **Export:** Included in full ZIP backup as `customer_profiles.json`
- **Import:** Restored from backup; also supports `exportAllProfiles()` and `importAllProfiles(_:)` for standalone transfer
- **Source:** `CustomerProfileViewModel.swift`

---

## 7. Subscription & Monetization

### 7.1 RevenueCat Integration
- **SDK:** RevenueCat Purchases framework
- **Configuration:** API key loaded from `Info.plist` (`RevenueCatAPIKey` or `REVENUECAT_API_KEY`)
- **Entitlement ID:** `"PoolFlow Premium"`
- **Product IDs:** `poolflow_pro_monthly`, `poolflow_pro_annual`
- **Debug:** `Purchases.logLevel = .debug` in DEBUG builds

### 7.2 Three Subscription Tiers
- **Free:** Default tier; limited to 5 pools; no access to analytics, route optimization, backup/restore, or iCloud sync
- **Trial:** 7-day free trial of Pro; full access to all premium features; `isPremiumActive = true`, `isTrialActive = true`
- **Paid (Pro):** Monthly or annual subscription; full access to all premium features; `isPremiumActive = true`, `isTrialActive = false`

### 7.3 Free Tier Pool Cap
- **Limit:** 5 pools maximum (`SubscriptionManager.freePoolCap = 5`)
- **Enforcement:** `AddPoolView` checks `canAccess(.unlimitedPools, poolCount: currentCount)` before allowing pool creation
- **Paywall Trigger:** `PaywallContext.poolCapReached` -- "Free tier includes up to 5 pools. Upgrade to add more customers."

### 7.4 Premium Feature Gates
- **`PremiumFeature` enum:**
  - `.analytics` -- Profit Dashboard access
  - `.routeOptimization` -- Route optimization engine
  - `.backupRestore` -- Full ZIP backup and restore
  - `.unlimitedPools` -- More than 5 pools
- **Access Check:** `canAccess(_ feature, poolCount:)` returns true for paid/trial users; free users only pass `.unlimitedPools` when under the cap

### 7.5 Context-Specific Paywalls
- **`PaywallContext` enum:** 6 contexts, each with a unique title and subtitle:
  - `.analyticsTab` -- "Unlock Analytics"
  - `.optimizeRoute` -- "Unlock Route Optimization"
  - `.backupRestore` -- "Unlock Full Backup & Restore"
  - `.poolCapReached` -- "Upgrade for Unlimited Pools"
  - `.settingsUpgrade` -- "Upgrade to PoolFlow Pro"
  - `.cloudSync` -- "Unlock iCloud Sync"
- **Presentation:** `SubscriptionPaywallSheet` wraps RevenueCatUI `PaywallView`
- **Fallback:** `StubPaywallView` for UI tests; `BillingUnavailableView` when RevenueCat fails to initialize

### 7.6 Restore Purchases
- **Screen:** `SettingsView` -- subscription section
- **Behavior:** Calls `Purchases.shared.restorePurchases()` and updates subscription state from the returned `CustomerInfo`

### 7.7 Manage Subscription Link
- **Screen:** `SettingsView` -- "Manage Subscription" button
- **Behavior:** Opens `https://apps.apple.com/account/subscriptions` in Safari

### 7.8 Billing Unavailable Fallback
- **Trigger:** RevenueCat API key missing or `Purchases.configure` fails
- **Behavior:** App runs in free-tier fallback mode; `isBillingAvailable = false`; `billingUnavailableMessage` set; all premium gates enforce free tier
- **Logging:** Error logged via `os.Logger`

### 7.9 Trial Expiring Notification
- **Trigger:** When a trial subscription is detected, a local notification is scheduled for 1 day before the expiration date
- **Content:** "Your PoolFlow Pro trial ends tomorrow -- Upgrade now to keep unlimited pools, analytics, and route optimization."
- **Source:** `SubscriptionManager.updateFromCustomerInfo()` -> `NotificationManager.scheduleTrialExpiringReminder()`

---

## 8. Onboarding & Guided Setup

### 8.1 Interactive Onboarding Flow
- **Screen:** `OnboardingFlowView` -- full-screen cover on first launch
- **Flow Steps (7):**
  1. Welcome (`OnboardingWelcomeStep`)
  2. Question: User Type (`OnboardingProfilingStep`)
  3. Question: Feature Focus (`OnboardingProfilingStep`)
  4. Feature Highlights (3-page swipeable tour) (`OnboardingFeatureHighlightsStep`)
  5. Guided Action -- inline add-pool form (`OnboardingGuidedActionStep` -> `OnboardingInlineAddPoolView`)
  6. Import Method Selection (migrating/businessOwner users only) (`OnboardingImportMethodStep`)
  7. Complete
- **Progress:** Capsule-shaped dot indicators at the top showing current step (filled capsules for completed steps)
- **Source:** `OnboardingFlowViewModel.swift`
- **Components:** `OnboardingQuestionCard` -- reusable tap-to-select card with icon, title, subtitle, and checkmark for profiling questions

### 8.2 User Type Profiling
- **Screen:** `OnboardingFlowView` -- step 2 (`OnboardingProfilingStep`)
- **Options (card selection):**
  - **Brand New** ("Starting fresh -- I'm starting fresh, no customer list yet") -- first-time pool service operator
  - **Migrating** ("Bringing customers -- I have customers to bring over") -- switching from another tool
  - **Business Owner** ("Managing techs -- I manage techs and want analytics") -- managing a team of technicians
- **Impact:** Determines whether the Import Method Selection step (step 6) is shown; migrating and businessOwner users see the import method chooser after the guided action step

### 8.3 Pool Count Bracket (Deprecated)
- **Status:** Deprecated in the streamlined onboarding path; `onboardingPoolCount` key is explicitly removed during profile persistence
- **Previous Behavior:** Was step 3, asked pool count bracket (Small/Medium/Large), skipped for Brand New users
- **Reason:** Simplified flow no longer branches on pool count; import method selection step handles migration users directly

### 8.4 Feature Focus Selection
- **Screen:** `OnboardingFlowView` -- step 3
- **Options:**
  - **Route Focus** ("Getting my route organized")
  - **Chemistry Focus** ("Tracking water chemistry")
  - **Profit Focus** ("Seeing my profit per pool")
- **Storage:** Persisted to UserDefaults for Brand New users; used for potential future personalization

### 8.5 Feature Highlights Tour
- **Screen:** `OnboardingFeatureHighlightsStep` -- step 4
- **Pages (3 swipeable):**
  1. "Today's Route" -- route management highlight
  2. "Smart Water Chemistry" -- LSI and dosing highlight
  3. "Profit Analytics" -- profit dashboard highlight

### 8.6 Guided Action -- Add First Pool
- **Screen:** `OnboardingGuidedActionStep` -> `OnboardingInlineAddPoolView`
- **Trigger:** All users (step 5 of the flow)
- **Behavior:** Simplified inline pool creation form requiring only Customer Name, Address, and Service Day; pre-populates monthly fee and pool volume from `WaterChemistryDefaults`; includes address autocomplete via `AddressSearchCompleter` with background geocoding fallback
- **Persistence:** Sets `hasAddedFirstPoolInOnboarding = true` on successful save
- **Skip Option:** "I'll do this later" button advances past the step without adding a pool

### 8.7 Import Method Selection Step
- **Screen:** `OnboardingImportMethodStep` -- step 6 (migrating/businessOwner users only)
- **Trigger:** Shown after the guided action step for users with `userType == .migrating` or `.businessOwner`
- **Options:**
  - "Import customer list (.csv/.tsv/.txt)" -- completes onboarding with `OnboardingCompletionIntent.openCustomerImport`, which opens the CSV import flow in Settings
  - "Restore full backup (.zip)" -- completes onboarding with `OnboardingCompletionIntent.openBackupRestore`, which opens the backup restore flow in Settings
  - "I'll add pools manually first" -- completes onboarding without action
  - "Skip for now" -- completes onboarding without action
- **Completion Intent:** `OnboardingCompletionIntent` enum (`.none`, `.openCustomerImport`, `.openBackupRestore`) drives post-onboarding navigation

### 8.8 Post-Onboarding Contextual Tooltips
- **Manager:** `OnboardingGuideManager.swift`
- **4 Tooltip Kinds:**
  - `routeIntro` -- "Your Route at a Glance" -- shown on first route tab appearance after onboarding
  - `quickLogIntro` -- "One-Tap Logging" -- shown on first QuickLog open
  - `lsiDiscovery` -- "Your Water Score" -- shown after first quick log completion
  - `analyticsTeaser` -- "Profit Insights Await" -- shown after 3+ quick logs
- **Persistence:** Each tooltip shown only once, tracked via AppStorage flags
- **Component:** `ContextualTooltipView` -- floating tooltip with icon, title, message, dismiss button, and optional auto-dismiss timer
- **Material:** `.ultraThinMaterial` background with rounded corners and shadow

### 8.9 Legacy Static Onboarding Carousel
- **Screen:** `OnboardingView.swift` -- 6-page static carousel (retained as fallback)
- **Pages:** Welcome -> Today's Route -> Bring Your Data -> Notification Style -> Profit Analytics -> First Success Path
- **First Success Checklist:** Add your first pool, log your first service, check the profit dashboard
- **Navigation:** Skip / Back / Next / Get Started buttons

### 8.10 Onboarding Profile Persistence
- **Storage:** User type and feature focus (Brand New users only) stored to UserDefaults on onboarding completion; pool count bracket key is explicitly removed (deprecated)
- **Keys:** `onboardingUserType`, `onboardingFeatureFocus`, `onboardingCompletedVersion`
- **Note:** Feature focus is only persisted for Brand New users; `onboardingPoolCount` is cleared as part of the streamlined flow

### 8.11 Replay Onboarding
- **Screen:** `SettingsView` -- "Replay Onboarding" button
- **Behavior:** Sets `forceShowOnboarding = true`; the interactive onboarding flow re-presents on next view appearance

---

## 9. Notifications

### 9.1 Morning Route Summary
- **Description:** Per-service-day notification showing how many pools are scheduled
- **Time:** User-configurable (default 7:00 AM, stored as `routeSummaryReminderTime` in seconds: 25,200)
- **Body:** "You have X pool(s) scheduled today."
- **Trigger:** `UNCalendarNotificationTrigger` -- one notification scheduled per service day that has pools assigned
- **Identifier:** `poolflow.notification.morningRouteSummary.<weekday>`
- **Suppression:** When morning summary is enabled, low-stock reminder is automatically suppressed to limit to one operational notification per day

### 9.2 Low-Stock Reminder
- **Description:** Evening notification when chemicals are below threshold and pools are scheduled for the next day
- **Time:** 6:30 PM daily
- **Conditions:** At least one pool scheduled tomorrow AND at least one chemical below low-stock threshold
- **Body:** "X low-stock chemical(s) before Y scheduled stop(s)."
- **Identifier:** `poolflow.notification.lowStockForTomorrow`
- **Suppression:** Suppressed when morning route summary is enabled

### 9.3 Weekly Digest
- **Description:** Weekly summary notification with pool count and analytics prompt
- **Time:** Sunday at 5:00 PM
- **Body:** "X active pools. Review analytics and route health before the new week."
- **Identifier:** `poolflow.notification.weeklyDigest`

### 9.4 Trial Expiring Reminder
- **Description:** One-time notification scheduled 1 day before trial subscription expiration
- **Body:** "Your PoolFlow Pro trial ends tomorrow -- Upgrade now to keep unlimited pools, analytics, and route optimization."
- **Trigger:** `UNCalendarNotificationTrigger` with exact date components, non-repeating
- **Identifier:** `poolflow.notification.trialExpiring`

### 9.5 Smart Permission Prompting
- **Description:** Notification authorization is NOT requested at first launch; eligibility is gated on demonstrated engagement
- **Eligibility Threshold:** `quickLogSuccessCount >= 3` OR `hasCompletedRouteOnce == true`
- **Primer Sheet:** "Stay Ahead of Tomorrow's Route" -- explains the three notification types, offers "Enable Notifications" and "Not Now" buttons
- **Post-Grant:** Immediately schedules notifications based on the user's selected scenarios
- **Philosophy:** Low-frequency, high-value notifications that respect user attention

---

## 10. Settings & Preferences

### 10.1 Default Pool Volume
- **Screen:** `SettingsView` -- "Defaults" section
- **Control:** Slider
- **Storage:** `defaultPoolVolume` AppStorage (default: 15,000 gallons)
- **Usage:** Pre-fills the pool volume field when creating new pools

### 10.2 Appearance Theme
- **Screen:** `SettingsView` -- "Appearance" section
- **Options:** System (default), Light, Dark
- **Storage:** `preferredAppearance` AppStorage
- **Implementation:** `PoolFlowApp` applies `.preferredColorScheme()` based on selection

### 10.3 Language Override
- **Screen:** `SettingsView` -- "Appearance" section
- **Options:** System (default), English (`en`), Spanish (`es`), French (`fr`), Portuguese Brazil (`pt-BR`), German (`de`)
- **Storage:** `preferredLanguageOverride` AppStorage
- **Implementation:** `PoolFlowApp` sets `environment(\.locale)` to the selected locale; view hierarchy re-rendered via `.id(preferredLanguageOverride)`

### 10.4 Chemical Inventory Management
- **Screen:** `SettingsView` -- "Chemical Inventory" section
- **Display:** List of all chemicals with name, type, stock level, and low-stock indicator (yellow/red badge)
- **Actions:** Add new chemical, edit existing (opens `EditInventoryItemView`), delete (swipe)
- **Low-Stock Badge:** Shown in the Settings tab badge count (`lowStockCount`)

### 10.5 Quick Log Confirm Before Save
- **Screen:** `SettingsView` -- "Workflow" section
- **Toggle:** When on, shows a confirmation dialog before saving a quick log
- **Storage:** `quickLogConfirmBeforeSave` AppStorage (default: off)

### 10.6 Backup & Restore Beta Toggle
- **Screen:** `SettingsView` -- "Workflow" section
- **Toggle:** Enables/disables full backup and restore functionality
- **Storage:** `featureBackupRestoreEnabled` AppStorage (default: off)

### 10.7 Route Optimization Objective
- **Screen:** `SettingsView` -- "Workflow" section
- **Picker:** Minimize Drive Time / Minimize Distance / Balanced
- **Storage:** `routeOptimizationObjective` AppStorage

### 10.8 Subscription Status & Actions
- **Screen:** `SettingsView` -- "Subscription" section
- **Display:** Current plan (Free / Trial / Pro), trial or renewal expiration date
- **Actions:**
  - "Upgrade" button (free users) -- opens paywall with `PaywallContext.settingsUpgrade`
  - "Restore Purchases" button
  - "Manage Subscription" button (paid/trial users) -- opens App Store subscriptions page

### 10.9 Data & Reports Section
- **Screen:** `SettingsView` -- "Data & Reports" section
- **Export Actions:**
  - Export All Pools (CSV)
  - Export Service History (CSV)
  - Export Inventory (CSV)
  - Monthly Performance (PDF)
  - Full Backup (.zip) -- Pro only
- **Import Actions:**
  - Restore from Backup (.zip) -- Pro only, with preview sheet
  - Download Import Template (CSV)
  - Import Data (CSV) -- with preview sheet showing creates/updates/skips/issues
- **Destructive:** Clear All App Data

### 10.10 Notification Configuration
- **Screen:** `SettingsView` -- "Notifications" section
- **Master Toggle:** Enable/disable all notifications
- **Per-Scenario Toggles:** Morning Route Summary, Low-Stock Alerts, Weekly Digest
- **Time Picker:** Morning summary notification time (time-of-day picker)
- **Reschedule Button:** Manually re-schedules all enabled notifications

### 10.11 Data Health Indicators
- **Screen:** `SettingsView` -- "Data Health" section
- **Checks:**
  - Pools with missing coordinates (lat/lon = 0)
  - Pools with missing service fee ($0)
  - Stale pools (last service > 35 days ago)
- **Display:** Count and descriptive label for each issue category

### 10.12 iCloud Sync Status
- **Screen:** `SettingsView` -- "iCloud Sync" section
- **Monitor:** `CloudSyncMonitor` observes `NSPersistentCloudKitContainer` notifications
- **States:** Idle, Syncing, Synced (with last sync date), Error (with message), Account Unavailable
- **Requirement:** Pro subscription; uses `CKContainer.default().accountStatus()` to verify iCloud availability
- **CloudKit:** Enabled via `ModelConfiguration(cloudKitDatabase: .automatic)` for Pro users

### 10.13 About Section
- **Screen:** `SettingsView` -- "About" section
- **Display:** App version number, build number
- **Links:** Privacy Policy (URL), Terms of Service (URL)

### 10.14 AppStorage Keys Registry
- **Source:** `AppPreferences.swift` -- `AppStorageKey` enum centralizes all storage key strings
- **Categories:** Defaults, Appearance, Analytics period/sort, Workflow toggles, Notification preferences, Onboarding flags, Localization/Units, Guide tooltip flags, App review tracking

---

## 11. Localization & Units

### 11.1 Supported Languages
- **Primary:** English (en)
- **Translations:** Spanish (es), French (fr), Portuguese Brazil (pt-BR), German (de)
- **System:** `Localizable.xcstrings` string catalog
- **Override:** In-app language picker (Settings) allows overriding the system language without changing iOS settings

### 11.2 String Localization Pattern
- **Implementation:** `String(localized:defaultValue:)` used throughout all views and view models
- **Coverage:** All user-facing text including button labels, section headers, status labels, notification content, error messages, onboarding copy, and dosing instructions

### 11.3 Unit System Preference
- **Options:** Imperial (default for US region), Metric (default for all other regions)
- **Auto-Detection:** `UnitSystemPreference` checks `Locale.current.region?.identifier` -- US = imperial, all others = metric
- **Storage:** `preferredUnitSystem` AppStorage
- **Show Both Units Toggle:** When enabled, displays both unit systems simultaneously (e.g., "15,000 gal (56,781 L)")

### 11.4 Temperature Conversion
- **Display:** Fahrenheit (imperial) or Celsius (metric)
- **Conversion:** `fromFahrenheit()` and `toFahrenheit()` methods on `UnitManager`
- **Internal Storage:** All temperatures stored internally in Fahrenheit
- **Input Range:** Adjusts slider range based on unit system

### 11.5 Volume and Weight Conversion
- **Volume:** Gallons (imperial) / Liters (metric) -- conversion: 1 gal = 3.78541 L
- **Weight (dry chemicals):** Ounces / Grams -- conversion: 1 oz = 28.3495 g
- **Liquid (wet chemicals):** Fluid ounces / Milliliters -- conversion: 1 fl oz = 29.5735 mL
- **Currency:** `UnitManager.formatCurrency()` uses locale-aware `NumberFormatter` with `.currency` style

### 11.6 Region-Aware Chemistry Defaults
- **Source:** `WaterChemistryDefaults.swift`
- **Regional Variants:**
  - US/CA: 78 degrees F water temp, 15,000 gal pool volume
  - GB/DE: 20 degrees C (68 degrees F) water temp, 40,000 L pool volume
  - AU/FR: 28 degrees C (82 degrees F) water temp, 50,000 L pool volume
  - ES/BR: 26 degrees C (79 degrees F) water temp, 45,000 L pool volume
- **Purpose:** Sensible initial values for new pools based on the user's region

---

## 12. Platform, Layout & UX Polish

### 12.1 iPhone Layout (TabView)
- **Navigation:** 4-tab bar at the bottom
- **Tabs:**
  - "Today's Route" (map.fill) -- badge shows unserviced pool count for today
  - "LSI Calculator" (drop.fill)
  - "Analytics" (chart.bar.fill)
  - "Settings" (gearshape.fill) -- badge shows low-stock chemical count
- **Grid:** 2-column layout for dashboard tiles and reading inputs

### 12.2 iPad Layout (NavigationSplitView)
- **Navigation:** Sidebar + detail pane
- **Sidebar:** List of 4 sections (Today's Route, LSI Calculator, Analytics, Settings)
- **Detail:** Renders the selected section's view
- **Grid:** 3-column layout for dashboard tiles and reading inputs
- **Max Content Width:** 700pt constraint (`Theme.Adaptive.maxContentWidth`)
- **Adaptive Charts:** 280pt chart height (vs 200pt on iPhone)
- **Adaptive Photos:** 120pt thumbnails (vs 80pt on iPhone)

### 12.3 Theme System
- **Source:** `Theme.swift` -- single source of truth for all visual constants
- **Touch Targets:** `minTouchTarget = 44pt`, `buttonHeight = 56pt` (glove-friendly)
- **Corner Radii:** `cornerRadius = 14pt`, `cardCornerRadius = 16pt`, `tileCornerRadius = 12pt`
- **Typography Scale:** Display (48pt bold rounded), Hero (64pt bold rounded), Section Header, Tile Value, Tile Label, Badge, Action, Metadata fonts
- **Color Mappings:**
  - LSI status: corrosive = blue, balanced = green, scaleForming = orange
  - Chemical types: acid = red, base = blue, calcium = cyan, alkalinity = teal, chlorine = yellow, stabilizer = indigo, dilution = orange, none = gray
  - Actions: primary = green, secondary = blue
- **Opacity:** Badge tint 15%, card tint 8%

### 12.4 Haptic Feedback System
- **Pre-Warmed Generators:** `UINotificationFeedbackGenerator`, `UIImpactFeedbackGenerator` (light and medium) -- created and prepared at app launch
- **Haptic Types:**
  - `hapticSuccess()` -- save confirmations, balanced LSI
  - `hapticWarning()` -- scale-forming LSI
  - `hapticError()` -- corrosive LSI, save failures, range limit reached
  - `hapticLight()` -- reading input increment/decrement
  - `hapticMedium()` -- drag-and-drop interactions
- **LSI-Aware:** `Theme.haptic(for:)` maps water condition to appropriate haptic

### 12.5 Accessibility
- **VoiceOver Labels:** All interactive elements have descriptive labels via `.accessibilityLabel()` and `.accessibilityHint()`
- **Combined Elements:** Service history rows combine date, LSI, pH, cost, and photo presence into a single accessibility element
- **LSI Accessibility:** `Theme.lsiAccessibilityLabel()` provides formatted "LSI +0.15, Balanced" strings
- **Reading Accessibility:** `Theme.readingAccessibilityLabel()` provides "pH 7.4, Ideal" formatted strings
- **Dynamic Type:** All fonts use SwiftUI system fonts that scale with the user's text size preference
- **Accessibility Identifiers:** All key interactive elements have `.accessibilityIdentifier()` for UI testing

### 12.6 App Review Prompts
- **Source:** `AppReviewManager.swift`
- **Triggers:**
  - `quickLogMilestone` -- at 5, 15, and 50 quick log completions
  - `routeComplete` -- first route completion
- **Guards:**
  - Maximum 1 review request per app version
  - Minimum 60-day gap between requests
- **Implementation:** `SKStoreReviewController.requestReview(in:)`

### 12.7 SwiftData Persistence
- **Schema:** `Pool`, `ServiceEvent`, `ChemicalDose`, `ChemicalInventory`, `Equipment`
- **Relationships:** Pool -> ServiceEvents (cascade), Pool -> Equipment (cascade), ServiceEvent -> ChemicalDoses (cascade), ChemicalDose -> ChemicalInventory (optional reference)
- **External Storage:** `ServiceEvent.photoData` uses `@Attribute(.externalStorage)`
- **Default Seeding:** 7 chemicals auto-inserted on first launch when inventory is empty

### 12.8 iCloud Sync (Pro)
- **Requirement:** Pro subscription
- **Implementation:** `ModelConfiguration(cloudKitDatabase: .automatic)` enables CloudKit sync for Pro users
- **Monitor:** `CloudSyncMonitor` actor checks `CKContainer.default().accountStatus()` and observes `NSPersistentCloudKitContainer.eventChangedNotification`
- **States:** idle, syncing, synced(Date), error(String), accountUnavailable

### 12.9 Address Search & Geocoding
- **Autocomplete:** `AddressSearchCompleter` wraps `MKLocalSearchCompleter` with 250ms debounce, minimum 3-character query, address-type results only
- **Suggestions:** Up to 5 suggestions displayed below the address field in pool forms
- **Resolution:** Selected suggestion resolved to full address + coordinates via `MKLocalSearch`
- **Geocoding Fallback:** `CLGeocoder` used post-save when coordinates are still missing
- **Source:** `AddressSearchCompleter.swift`, `PoolFormFields.swift`

### 12.10 Pool Detail View
- **Screen:** `PoolDetailView` -- navigated from pool list or analytics cards
- **Sections:**
  - Customer header (name, address, service day, route order)
  - Customer profile card (contact info, gate access, arrival window, tags) with edit sheet
  - LSI summary card (current LSI, water condition, last service date)
  - Chemistry grid (5 tiles: pH, Temp, Calcium, Alkalinity, CYA with range status indicators)
  - Chemistry trend chart (pH + shifted LSI over last 15 visits)
  - Profit card (monthly fee, chemical cost, net profit; "IN THE RED" badge for money losers)
  - Equipment section (preview 3 items + "View All Equipment" link)
  - Action buttons: "Quick Log Service", "Run Dosing Calculator", "Chemical Usage History"
  - Photo gallery (horizontal scroll of proof-of-service photos)
  - Service history preview (6 most recent events + "View Full History" link)
- **Toolbar:** Edit pool, Export menu (CSV, Customer Visit PDF, Email Report to Customer)

---

## Feature Matrix: Free vs. Pro

| Feature | Free | Trial (7 days) | Pro (Monthly/Annual) |
|---------|:----:|:--------------:|:-------------------:|
| Pool management (add/edit/delete) | Up to 5 pools | Unlimited | Unlimited |
| Water chemistry inputs & LSI calculation | Yes | Yes | Yes |
| Dosing recommendations | Yes | Yes | Yes |
| Quick Log service visits | Yes | Yes | Yes |
| Proof-of-service photos | Yes | Yes | Yes |
| Service history & trend charts | Yes | Yes | Yes |
| Chemical inventory management | Yes | Yes | Yes |
| Equipment tracking | Yes | Yes | Yes |
| Day-of-week route filtering | Yes | Yes | Yes |
| Drag-and-drop route reordering | Yes | Yes | Yes |
| One-tap Apple Maps directions | Yes | Yes | Yes |
| Route search and filtering | Yes | Yes | Yes |
| Address autocomplete & geocoding | Yes | Yes | Yes |
| Route progress tracking | Yes | Yes | Yes |
| Route completion celebration | Yes | Yes | Yes |
| Customer profiles | Yes | Yes | Yes |
| Notifications (all types) | Yes | Yes | Yes |
| Appearance theme (light/dark/system) | Yes | Yes | Yes |
| Language override (5 languages) | Yes | Yes | Yes |
| Unit system (imperial/metric) | Yes | Yes | Yes |
| Data health indicators | Yes | Yes | Yes |
| CSV export (all scopes) | Yes | Yes | Yes |
| CSV import (bulk customer upload) | Yes | Yes | Yes |
| Import template download | Yes | Yes | Yes |
| PDF reports (customer visit, performance) | Yes | Yes | Yes |
| Email report to customer | Yes | Yes | Yes |
| Chemical usage history view | Yes | Yes | Yes |
| Onboarding & guided setup | Yes | Yes | Yes |
| Contextual tooltips | Yes | Yes | Yes |
| **Route optimization engine** | No | Yes | Yes |
| **Profit analytics dashboard** | No | Yes | Yes |
| **Full backup & restore (.zip)** | No | Yes | Yes |
| **iCloud sync across devices** | No | Yes | Yes |
| **Unlimited pools (>5)** | No | Yes | Yes |

---

## Appendix A: Source File Inventory

| Directory | File | Primary Responsibility |
|-----------|------|-----------------------|
| Models/ | `Pool.swift` | Core pool data model with chemistry readings, service day, route order, geocoordinates |
| Models/ | `ServiceEvent.swift` | Service visit record with readings, photo, chemical doses, tech notes |
| Models/ | `Equipment.swift` | Pool equipment with type, manufacturer, warranty, service dates |
| Models/ | `ChemicalInventory.swift` | Chemical stock tracking with type, cost, concentration, low-stock threshold |
| Models/ | `WaterChemistryDefaults.swift` | Region-aware default values for chemistry readings and pool parameters |
| Engine/ | `LSICalculator.swift` | Langelier Saturation Index calculation with lookup table interpolation |
| Engine/ | `DosingEngine.swift` | Prioritized dosing recommendations and profit analysis |
| Engine/ | `DosingFormatter.swift` | Unit-aware dosing quantity and instruction formatting |
| ViewModels/ | `SubscriptionManager.swift` | RevenueCat subscription state, tier management, feature gates |
| ViewModels/ | `RouteOptimizationEngine.swift` | Nearest-neighbor + 2-opt route optimization |
| ViewModels/ | `NotificationManager.swift` | Local notification scheduling for 4 scenarios |
| ViewModels/ | `OnboardingFlowViewModel.swift` | Interactive onboarding flow state machine |
| ViewModels/ | `OnboardingGuideManager.swift` | Post-onboarding contextual tooltip management |
| ViewModels/ | `DosingViewModel.swift` | Bridges chemistry inputs to LSI engine with haptic feedback |
| ViewModels/ | `PoolListViewModel.swift` | Day filtering, drag-and-drop reordering, localized day labels |
| ViewModels/ | `CustomerProfileViewModel.swift` | Per-pool customer profiles in UserDefaults |
| ViewModels/ | `DataExportService.swift` | CSV, PDF, and ZIP export generation |
| ViewModels/ | `DataImportService.swift` | CSV import staging and full backup restore |
| ViewModels/ | `FullBackupModels.swift` | Backup record types and schema versioning (v1/v2) |
| ViewModels/ | `BackupCodec.swift` | ZIP backup archive encoding/decoding protocol and `ZIPBackupCodec` actor implementation |
| ViewModels/ | `CloudSyncMonitor.swift` | iCloud/CloudKit sync status monitoring |
| ViewModels/ | `PDFReportRenderer.swift` | Customer visit and business summary PDF generation |
| ViewModels/ | `TravelTimeEstimator.swift` | Hybrid MapKit ETA + haversine fallback travel time |
| ViewModels/ | `AddressSearchCompleter.swift` | MKLocalSearchCompleter wrapper with debounce |
| ViewModels/ | `AppReviewManager.swift` | Milestone-based App Store review prompts |
| Views/ | `PoolListView.swift` | Main route list with day picker, optimization, progress bar |
| Views/ | `PoolDetailView.swift` | Per-pool detail with chemistry, equipment, profit, history |
| Views/ | `AddPoolView.swift` | New pool creation form with geocoding |
| Views/ | `EditPoolView.swift` | Existing pool editing form |
| Views/ | `QuickLogView.swift` | Half-sheet quick service logging workflow |
| Views/ | `DosingCalculatorView.swift` | Full LSI calculator with sliders and action steps |
| Views/ | `ProfitDashboardView.swift` | Analytics dashboard with sort/filter and per-pool cards |
| Views/ | `SettingsView.swift` | All app settings, preferences, data management, subscription |
| Views/ | `EquipmentListView.swift` | Per-pool equipment list with CRUD |
| Views/ | `EditEquipmentView.swift` | Equipment add/edit form |
| Views/ | `EditInventoryItemView.swift` | Chemical inventory add/edit form |
| Views/ | `EditServiceEventView.swift` | Past service event editing |
| Views/ | `ServiceHistoryView.swift` | Full service history with search, edit, delete |
| Views/ | `ChemicalUsageHistoryView.swift` | Per-pool chemical cost tracking with trend chart |
| Views/ | `SubscriptionPaywallSheet.swift` | RevenueCatUI paywall with context-specific messaging |
| Views/ | `PoolFormFields.swift` | Shared form sections for pool creation/editing |
| Views/ | `ReadingInputComponent.swift` | Shared chemistry input (slider and compact modes) |
| Views/ | `MailComposeView.swift` | MFMailComposeViewController wrapper for email reports |
| Views/ | `ActivityShareSheet.swift` | UIActivityViewController wrapper for sharing |
| Views/ | `StoreRecoveryView.swift` | Database corruption recovery UI |
| Views/Onboarding/ | `OnboardingFlowView.swift` | Interactive onboarding flow coordinator |
| Views/Onboarding/ | `OnboardingWelcomeStep.swift` | Hero welcome screen with "Get Started" call to action |
| Views/Onboarding/ | `OnboardingProfilingStep.swift` | Generic profiling question screen with card grid |
| Views/Onboarding/ | `OnboardingQuestionCard.swift` | Reusable tap-to-select card for profiling questions |
| Views/Onboarding/ | `OnboardingFeatureHighlightsStep.swift` | 3-page feature tour carousel |
| Views/Onboarding/ | `OnboardingGuidedActionStep.swift` | Inline add-pool wrapper for onboarding guided action step |
| Views/Onboarding/ | `OnboardingInlineAddPoolView.swift` | Simplified inline add-pool form (name, address, service day) |
| Views/Onboarding/ | `OnboardingImportMethodStep.swift` | Import method chooser (CSV, backup restore, manual, skip) |
| Views/ | `OnboardingView.swift` | Legacy 6-page static onboarding carousel |
| Views/Guide/ | `ContextualTooltipView.swift` | Floating tooltip component with auto-dismiss |
| Views/Guide/ | `OnboardingGuideOverlay.swift` | Environment key for guide manager injection |
| App/ | `PoolFlowApp.swift` | App entry point, SwiftData container, tab/split navigation |
| App/ | `AppPreferences.swift` | Centralized AppStorage key registry, `OnboardingCompletionIntent`, `SettingsPendingImportLaunchMode` |
| App/ | `AppServices.swift` | Centralized service dependency container (subscription, notifications, import, export, profiles) |
| App/ | `AppStrings.swift` | Locale-aware string resolution utility with bundle lookup for runtime localization |
| App/ | `AppLocaleResolver.swift` | Locale/region/currency resolution, `AppFormatters` for number, currency, and signed number formatting |
| App/ | `UnitSystem.swift` | Imperial/metric unit management and conversions |
| App/ | `Theme.swift` | Visual constants, colors, typography, haptics, adaptive layout |

---

*This document catalogs all 114 features across 12 feature groups in the current PoolFlow codebase. Every feature listed was verified against the corresponding source file as of v2.1 (2026-02-25). For detailed behavioral specifications, see [04_Functional_Scope](04_Functional_Scope.md). For user flow maps, see [05_Customer_Journeys](05_Customer_Journeys.md).*
