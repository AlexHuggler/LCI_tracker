# PoolFlow — Customer Journeys

> **Document:** 05_Customer_Journeys
> **Version:** 2.1
> **Last Updated:** 2026-02-25
> **Related Docs:** [01_App_Blueprint](01_App_Blueprint.md) | [02_Product_Strategy](02_Product_Strategy.md) | [03_Feature_Inventory](03_Feature_Inventory.md) | [04_Functional_Scope](04_Functional_Scope.md)

---

## Overview

This document traces every primary user flow through PoolFlow as implemented in the SwiftUI codebase. Each journey describes the exact screens, button labels, sheet presentations, navigation patterns, and state transitions a user encounters. Where the app makes gating decisions (subscription checks, feature flags, notification eligibility), those decision points are documented inline.

PoolFlow uses a four-tab layout on iPhone (`TabView`) and a `NavigationSplitView` sidebar on iPad. The four top-level destinations are:

| Tab | Label | Icon | View | Gating |
|-----|-------|------|------|--------|
| 1 | Today's Route | `map.fill` | `PoolListView` | None |
| 2 | LSI Calculator | `drop.fill` | `DosingCalculatorView` | None |
| 3 | Analytics | `chart.bar.fill` | `ProfitDashboardView` | Pro subscription required |
| 4 | Settings | `gearshape.fill` | `SettingsView` | None (badge: low-stock count) |

The Today's Route tab also shows a badge with the count of unserviced pools for the current weekday.

---

## Journey 1: First Launch & Onboarding

**Actor:** New user installing PoolFlow for the first time
**Goal:** Understand the app, answer profiling questions, and optionally add a first pool or import CSV
**Duration:** ~2-3 minutes
**Entry Condition:** `hasSeenOnboarding == false` or `forceShowOnboarding == true`

### Step-by-Step Flow

```
App Launch
  |
  +-- PoolFlowApp.rootView resolves startup state:
  |     .loading  --> "Opening PoolFlow Data" spinner + "Checking your local database..."
  |     .ready    --> ContentView
  |     .recovery --> StoreRecoveryView (see Journey 10)
  |
  +-- ContentView.onAppear checks hasSeenOnboarding
  |     If false --> presents OnboardingFlowView as .fullScreenCover
  |
  v
OnboardingFlowView (full-screen cover, 5-6 steps depending on user type)
  |
  +-- STEP 1: OnboardingWelcomeStep
  |     - Hero icon: drop.fill (blue, 72pt)
  |     - Title: "Welcome to PoolFlow"
  |     - Subtitle: "Let's set up PoolFlow for how you work."
  |     - Body: "Three quick questions so we can skip what you don't need."
  |     - CTA button: "Get Started" (Theme.primaryActionColor)
  |     - No Back/Skip controls on this step
  |     - Haptic: hapticLight() on tap
  |
  +-- STEP 2: OnboardingProfilingStep — "What brings you to PoolFlow?"
  |     - Subtitle: "To customize your workspace..."
  |     - Three tap-to-select cards (OnboardingQuestionCard):
  |       [1] "Starting fresh" (plus.circle.fill, blue) — "I'm starting fresh — no customer list yet" (brandNew)
  |       [2] "Bringing customers" (square.and.arrow.down, orange) — "I have customers to bring over" (migrating)
  |       [3] "Managing techs" (chart.bar.fill, purple) — "I manage techs and want analytics" (businessOwner)
  |     - Selected card shows checkmark.circle.fill + tinted background + border
  |     - CTA: "Continue" (enabled when selection made) / "Select an option" (disabled)
  |     - Top bar: Back chevron + "Skip" button
  |     - Progress dots: animated capsules showing step progress
  |     - Haptic: hapticLight() on card tap
  |
  +-- STEP 3: OnboardingProfilingStep — "What's most important to you right now?"
  |     - Subtitle: "We'll highlight this first after setup."
  |     - Three cards:
  |       [1] "Route organized" (map.fill, green) — "Getting my route organized" (routeFocus)
  |       [2] "Water chemistry" (drop.fill, blue) — "Tracking water chemistry" (chemistryFocus)
  |       [3] "Profit per pool" (chart.bar.fill, purple) — "Seeing my profit per pool" (profitFocus)
  |     - CTA: "Continue" / "Select an option"
  |     - NOTE: Pool count question has been removed from the streamlined onboarding path
  |
  +-- STEP 4: OnboardingFeatureHighlightsStep — Swipeable 3-page feature tour
  |     - Paged TabView with page indicator dots
  |     - Page 1: "Today's Route" (map.fill, green)
  |       "Work your day in order and track completion live."
  |       "Filter by day, drag to reorder, get one-tap directions, and quick-log service from the route list."
  |     - Page 2: "Smart Water Chemistry" (drop.fill, blue)
  |       "Real-time LSI calculations and dosing recommendations."
  |       "Slide readings to watch the LSI index animate. Get chemical recommendations with cost estimates."
  |     - Page 3: "Profit Analytics" (chart.bar.fill, purple)
  |       "Spot money-loser pools and act fast."
  |       "Sort by worst margin, highest chemical spend, or money-loser first. Run dosing or open detail directly."
  |     - CTA: "Next" (blue) on pages 1-2, "Continue" (primaryAction) on page 3
  |     - Haptic: hapticLight() on each tap
  |
  +-- STEP 5: OnboardingGuidedActionStep — Inline add-pool form (all user types)
  |     |
  |     |   OnboardingInlineAddPoolView
  |     |     - Header: "Add Your First Pool"
  |     |     - Subtitle: "Just the basics — you can fill in details later."
  |     |     - Fields:
  |     |       [1] Customer Name (TextField, placeholder "e.g. Smith Residence")
  |     |       [2] Address (TextField with MKLocalSearchCompleter autocomplete, up to 5 suggestions)
  |     |       [3] Service Day (segmented Picker, Sun-Sat, defaults to today's weekday)
  |     |     - Pre-populates monthlyServiceFee and poolVolumeGallons from WaterChemistryDefaults
  |     |     - CTA: "Add Pool & Continue" (primaryActionColor, disabled until name+address non-empty)
  |     |     - Secondary: "I'll do this later" (dismisses without saving)
  |     |     - On save: inserts Pool into SwiftData, hapticSuccess(), background geocode if no coords
  |     |     - Sets hasAddedFirstPoolInOnboarding = true
  |     |
  |     +-- For brandNew/nil users: onComplete advances to .complete (onboarding finishes)
  |     +-- For migrating/businessOwner users: onComplete advances to .importMethodSelection (Step 6)
  |
  +-- STEP 6 (conditional): OnboardingImportMethodStep — Import chooser
        ONLY shown for migrating or businessOwner user types
        |
        - Icon: square.and.arrow.down (orange, 64pt)
        - Title: "Bring Your Customers Over"
        - Subtitle: "Choose how you want to move your customer records into PoolFlow."
        - Four action buttons:
          [1] "Import customer list (.csv/.tsv/.txt)" (tablecells, orange background)
              --> completes onboarding with intent .openCustomerImport
          [2] "Restore full backup (.zip)" (archivebox, secondary background)
              --> completes onboarding with intent .openBackupRestore
          [3] "I'll add pools manually first" (secondaryActionColor text)
              --> completes onboarding with intent .none
          [4] "Skip for now" (secondary text)
              --> completes onboarding with intent .none
```

### Post-Onboarding Transitions

When onboarding completes (via any path), `completeOnboarding(intent:)` runs:
1. `flowViewModel.persistProfile()` saves userType to UserDefaults (featureFocus saved only for brandNew users; poolCountBracket is deprecated and cleared)
2. `hasSeenOnboarding = true`, `forceShowOnboarding = false`
3. `guideManager.markOnboardingComplete()` enables post-onboarding contextual tooltips
4. Based on `OnboardingCompletionIntent`:
   - `.openCustomerImport`: sets `settingsPendingImportLaunchMode = .customerDelimitedText`, switches tab to Settings
   - `.openBackupRestore`: sets `settingsPendingImportLaunchMode = .backupRestore`, switches tab to Settings
   - `.none`: no additional action (also checks legacy `postOnboardingOpenImport` flag as fallback)

### Post-Onboarding Contextual Guide System

After onboarding completes, `OnboardingGuideManager` drives one-time contextual tooltips (each shown exactly once, tracked via AppStorage flags):

| Tooltip | Trigger | Content |
|---------|---------|---------|
| `routeIntro` | First visit to Route tab | "Swipe right on any pool to Quick Log. Drag rows to reorder your route." |
| `quickLogIntro` | First Quick Log sheet open | "Readings are pre-filled from last visit. Just tap Log & Done." |
| `lsiDiscovery` | After first Quick Log save | "Try the LSI Calculator. Slide readings to see dosing update live." |
| `analyticsTeaser` | After 3+ Quick Log saves | (Analytics teaser tooltip) |

Each tooltip uses `ContextualTooltipView` with a "Got it" dismiss button. The `quickLogIntro` tooltip also auto-dismisses after 5 seconds.

---

## Journey 2: Daily Route Workflow

**Actor:** Pool technician starting their workday
**Goal:** View today's pools in order, navigate to each, service them, track completion
**Duration:** Full workday (route review: ~30 seconds; per-pool service: ~2 minutes each)

### Step-by-Step Flow

```
Open App --> Today's Route tab (PoolListView)
  |
  +-- Navigation title: "Route"
  |
  +-- DAY PICKER (horizontal scroll, circular chips)
  |     - 7 day buttons (Sun-Sat, localized via Calendar.shortWeekdaySymbols)
  |     - Defaults to today's weekday
  |     - Each chip shows pool count for that day
  |     - Selected day: blue fill, white text, bold
  |     - Haptic: hapticLight() on day change
  |
  +-- ROUTE PROGRESS BAR
  |     - Text: "X of Y serviced"
  |     - Progress bar: blue fill, animates with spring(duration: 0.4)
  |     - When all serviced: bar turns green, text shows "Complete"
  |     - Only visible when totalDayPools > 0
  |
  +-- POOL LIST (List with .plain style)
  |     Each row (poolRow) shows:
  |     |
  |     +-- Route order badge (circle):
  |     |     - Unserviced: blue circle with route number (1, 2, 3...)
  |     |     - Serviced today: green circle with checkmark
  |     |
  |     +-- Pool info column:
  |     |     - Customer name (.headline)
  |     |     - Address (.caption, 2-line limit)
  |     |     - Last service: "Today" / "Yesterday" / "X days ago" / "X weeks ago"
  |     |
  |     +-- LSI badge (capsule):
  |     |     - Format: "+0.1" / "-0.3" etc.
  |     |     - Color: green (balanced), red (corrosive), orange (scale-forming)
  |     |
  |     +-- Directions button (arrow.triangle.turn.up.right.circle.fill):
  |           - Green, .title size
  |           - Opens Apple Maps with driving directions
  |           - If pool has coordinates: MKMapItem.openInMaps()
  |           - If no coordinates: falls back to address search URL
  |
  +-- SWIPE ACTIONS:
  |     - Swipe LEFT (trailing): "Complete" (green, checkmark.circle) --> opens QuickLogView sheet
  |     - Swipe RIGHT (leading): "Delete" (red, trash) --> delete confirmation alert
  |
  +-- CONTEXT MENU (long press):
  |     - "Quick Log" (checkmark.circle)
  |     - "Get Directions" (arrow.triangle.turn.up.right.circle)
  |     - Divider
  |     - "Delete Pool" (trash, destructive)
  |
  +-- TAP ROW --> NavigationLink to PoolDetailView
  |
  +-- DRAG TO REORDER: .onMove modifier, persists new routeOrder to SwiftData
  |
  +-- SEARCH: .searchable(prompt: "Search pools") — filters by name, address, notes
  |
  +-- TOOLBAR (primaryAction):
  |     [1] Optimization settings (slider.horizontal.3) — Menu with Picker for objective:
  |         - "Min Drive Time" (minDriveTime, default)
  |         - "Min Drive Distance" (minDriveDistance)
  |         - "Balanced" (balanced)
  |     [2] Optimize Route (wand.and.stars) — runs route optimization (see Journey 5)
  |         - Disabled if < 2 pools or optimization in progress
  |         - Shows ProgressView while computing
  |         - GATED: requires Pro subscription (canAccess(.routeOptimization, poolCount:))
  |           If free tier: presents SubscriptionPaywallSheet with context .optimizeRoute
  |     [3] Add Pool (plus.circle.fill) — presents AddPoolView as sheet
  |
  +-- EMPTY STATE (when no pools for selected day):
  |     ContentUnavailableView: "No Pools on [Day]" / "No Results"
  |     "Tap + to add a pool to this day's route."
  |
  +-- ROUTE COMPLETION CELEBRATION (when servicedCount == totalDayPools, minimum 3 pools):
        - hasCompletedRouteOnce = true
        - notificationPromptEligible = true
        - hapticSuccess()
        - Overlay: checkmark.seal.fill (green, 64pt) + "Route Complete!" + "All X pools serviced"
        - Auto-dismisses after 2 seconds
        - Triggers app review prompt check
```

### Notification Primer (triggered by route workflow milestones)

After 3 quick logs OR completing a route, `evaluateNotificationPromptEligibility()` fires. If `notificationPromptShown == false` and `notificationsEnabledByUser == false`:

```
Notification Primer Sheet
  |
  +-- Title: "Stay Ahead of Tomorrow's Route"
  +-- Body: "Enable low-frequency reminders after your workflow is already working."
  +-- Benefits list:
  |     - "Morning Route Summary" (sun.max.fill)
  |     - "Low-stock heads-up for tomorrow" (exclamationmark.triangle.fill)
  |     - "Weekly performance digest" (chart.bar.fill)
  +-- CTA: "Enable Notifications" (.borderedProminent) --> requests OS authorization
  +-- Secondary: "Not Now" (.bordered)
  +-- Sets notificationPromptShown = true regardless of choice
```

---

## Journey 3: Quick Log Service Visit

**Actor:** Technician at a pool, ready to record service
**Goal:** Log water chemistry, confirm chemical doses, attach a proof photo, save in under 2 minutes
**Duration:** Target < 2 minutes
**Entry Points:**
- Swipe left on pool row in PoolListView --> "Complete" action
- Tap "Quick Log Service" button in PoolDetailView
- Tap "Quick Log" in pool row context menu
- Tap "Quick Log" button on a pool card in ProfitDashboardView

### Step-by-Step Flow

```
QuickLogView (presented as .sheet with .presentationDetents([.medium, .large]))
  |
  +-- Navigation title: "Log Service" (.inline)
  +-- Cancel button (placement: .cancellationAction)
  |
  +-- CONTEXTUAL TOOLTIP (first time only, via guideManager):
  |     "Readings are pre-filled from last visit. Just tap Log & Done."
  |     Auto-dismisses after 5 seconds
  |
  +-- LSI BADGE (top card):
  |     - Customer name + address
  |     - Live LSI value (e.g., "+0.12") with color + numeric animation
  |     - Updates instantly as readings change
  |
  +-- READINGS GRID (LazyVGrid, compact mode with +/- buttons):
  |     - pH (6.0-9.0, step 0.1)
  |     - Temp (unit-aware: F or C)
  |     - Calcium (0-1000 ppm, step 25)
  |     - Alk (0-500 ppm, step 10)
  |     - CYA (0-300 ppm, step 10)
  |     - PRE-FILLED from pool.latestReadings() (last ServiceEvent or pool defaults)
  |     - Each +/- tap triggers hapticLight() or hapticError() at range bounds
  |
  +-- CHEMICALS APPLIED SECTION:
  |     - Header: "CHEMICALS APPLIED"
  |     - If water balanced: checkmark.seal.fill + "Water is balanced"
  |     - Otherwise: list of DosingEngine recommendations
  |       Each row: toggle circle + chemical name + quantity (formatted) + cost
  |       Tap to confirm/unconfirm a dose (circle/checkmark.circle.fill)
  |       All actionable recommendations auto-selected on load
  |     - Haptic: hapticLight() on each toggle
  |
  +-- COST SUMMARY:
  |     - "Chemical Cost" label + total of confirmed doses (orange, bold)
  |
  +-- NOTES FIELD:
  |     - TextEditor with "Notes (optional)" placeholder
  |     - Min height 72px, max 120px
  |
  +-- PHOTO SECTION:
  |     - PhotosPicker: "Add Proof Photo" / "Photo Added" (camera.fill icon)
  |     - Selected image downsampled to 1200px max, JPEG 80% quality
  |     - Thumbnail preview shown below picker
  |
  +-- SHARE REPORT:
  |     - ShareLink: "Share Report" (square.and.arrow.up)
  |     - Generates plain-text service report with all readings
  |
  +-- STICKY "LOG & DONE" BUTTON (safeAreaInset, bottom):
        |
        +-- If quickLogConfirmBeforeSave == true:
        |     Confirmation dialog: "Log service for [Customer]?"
        |     Shows: pH, LSI, chemical cost
        |     "Confirm Log & Done" / "Cancel"
        |
        +-- SAVE SEQUENCE:
        |     1. Create ServiceEvent with all readings, LSI, photo, notes, cost
        |     2. Create ChemicalDose records for each confirmed recommendation
        |     3. Decrement ChemicalInventory.currentStockOz for each dose (clamp at 0)
        |     4. Update pool-level readings (pH, temp, calcium, alk, CYA)
        |     5. pool.recalculateLSI()
        |     6. Increment quickLogSuccessCount
        |     7. If count >= 3: set notificationPromptEligible = true
        |     8. Evaluate guide tooltips (lsiDiscovery, analyticsTeaser)
        |     9. Trigger app review check
        |
        +-- UNDO TOAST (overlaid on bottom):
        |     - "Service Logged" (checkmark.circle.fill, green)
        |     - "Undo" button (.bordered) -- reverses ALL save operations:
        |       Deletes ServiceEvent, restores inventory stock, restores pool readings,
        |       restores quickLogSuccessCount, restores notificationPromptEligible
        |     - "Done" button (.borderedProminent) -- dismisses immediately
        |     - Auto-dismisses after 5 seconds if no action taken
        |
        +-- Haptic: hapticSuccess() on save, hapticWarning() on undo, hapticError() on failure
```

---

## Journey 4: Chemistry Deep-Dive (Dosing Calculator)

**Actor:** Technician analyzing water chemistry in detail
**Goal:** Calculate LSI, understand water condition, get prioritized dosing recommendations
**Duration:** ~1-2 minutes
**Entry Points:**
- "LSI Calculator" tab (standalone, no pool pre-selected)
- "Run Dosing Calculator" button in PoolDetailView (pool pre-loaded)
- "Run Dosing" button on pool card in ProfitDashboardView

### Step-by-Step Flow

```
DosingCalculatorView
  |
  +-- Navigation title: "Dosing Calculator" (.large)
  |
  +-- CONTEXTUAL TOOLTIP (first time, after first Quick Log):
  |     "Try the LSI Calculator. Slide readings to see dosing update live."
  |
  +-- LSI GAUGE SECTION (hero card):
  |     - Header: "LSI INDEX"
  |     - Value: "+0.12" (heroFont, color-coded)
  |     - Status badge: "BALANCED" / "CORROSIVE" / "SCALE-FORMING" (capsule)
  |     - Description: localized explanation of water condition
  |     - Animated: .numericText transition, .snappy(0.25) animation
  |     - Haptic: fires on status boundary crossings (not every update)
  |
  +-- WATER READINGS SECTION (slider mode):
  |     - Header: "TEST KIT READINGS"
  |     - Each parameter: label + value display + minus/plus buttons + full-width Slider
  |       pH (6.0-9.0, step 0.1)
  |       Temp (unit-aware range, step varies by unit system)
  |       Calcium (0-1000 ppm, step 25)
  |       Alkalinity (0-500 ppm, step 10)
  |       CYA (0-300 ppm, step 10)
  |     - Each slider tinted per parameter (Theme.sliderTint)
  |     - Haptic: hapticLight() on +/- buttons
  |
  +-- POOL PARAMETERS SECTION:
  |     - Header: "POOL PARAMETERS"
  |     - TDS (0-5000 ppm, step 100)
  |     - Volume (unit-aware: gallons or liters)
  |
  +-- ACTION STEPS (recommendations card):
  |     - Header: "ACTION STEPS" + "Est. Cost: $X.XX" (orange)
  |     - Ordered list of DosingEngine.DosingRecommendation cards:
  |       Each card: priority number badge (colored circle) + instruction text + cost
  |       Priority coloring per chemical type
  |     - Updates in real-time as sliders move
  |
  +-- SAVE ACTIONS (context-dependent):
  |     - If opened from PoolDetailView (pool != nil):
  |       "Save Readings & Log Service" (primaryActionColor)
  |       --> saves readings to pool + creates ServiceEvent
  |     - If opened from standalone tab (pool == nil, pools exist):
  |       "Save to Pool..." (secondaryActionColor)
  |       --> presents pool picker sheet
  |     - "Service Logged" toast (green capsule, 2-second auto-dismiss)
  |
  +-- POOL PICKER SHEET (when saving from standalone):
  |     - Navigation title: "Select Pool"
  |     - Searchable: "Search by customer or address"
  |     - Sort menu (arrow.up.arrow.down.circle):
  |       "Today's Route" (default) / "Most Recent Service" / "A-Z"
  |     - Each row: customer name, address, service day, last service date
  |     - Tap pool --> saves readings and creates ServiceEvent
  |
  +-- TOOLBAR (if pool-bound):
        - "Reset" (arrow.counterclockwise) in secondary action: reloads pool's current readings
```

---

## Journey 5: Route Optimization

**Actor:** Technician with multiple pools wanting to minimize drive time
**Goal:** Preview and apply an optimized stop order
**Duration:** ~15-30 seconds
**Gating:** Pro subscription required

### Step-by-Step Flow

```
PoolListView toolbar --> tap wand.and.stars icon
  |
  +-- PRE-CHECKS:
  |     - Must have 2+ pools for selected day (button disabled otherwise)
  |     - Subscription check: canAccess(.routeOptimization, poolCount: allPools.count)
  |       If free tier: presents SubscriptionPaywallSheet(context: .optimizeRoute)
  |       Title: "Unlock Route Optimization"
  |       Subtitle: "Preview faster stop order and save drive time each route day."
  |       --> user must upgrade or cancel
  |
  +-- OPTIMIZATION RUNS (async):
  |     - wand.and.stars icon replaced with ProgressView while computing
  |     - RouteOptimizationEngine.optimize() runs:
  |       Phase 1: Nearest-neighbor seeding
  |       Phase 2: 2-opt improvement
  |       Travel time: MapKit ETA with Haversine fallback
  |
  +-- OPTIMIZATION PREVIEW SHEET:
  |     Navigation title: "Optimize Route" (.inline)
  |     |
  |     +-- "Estimated Drive Time" section:
  |     |     - Current: "42 min"
  |     |     - Optimized: "31 min"
  |     |     - Estimated Saved: "11 min" (green if positive)
  |     |     - ETA source note: "ETA uses MapKit where available..."
  |     |       or "ETA uses offline approximation in this preview."
  |     |
  |     +-- "Current Order" section: numbered list of pool names
  |     +-- "Optimized Order" section: numbered list of pool names
  |     +-- "Needs Coordinates" section (if any): pools without lat/lng
  |     |     "Stops without coordinates stay in place and are not dropped."
  |     |
  |     +-- Toolbar:
  |           "Cancel" (cancellationAction) --> dismiss, no changes
  |           "Apply" (confirmationAction, semibold) --> applies new order
  |             Disabled if optimized order equals current order
  |
  +-- APPLY:
  |     - Updates routeOrder on all pools for that day
  |     - Saves to SwiftData
  |     - hapticSuccess()
  |     - Shows UNDO TOAST (safeAreaInset, bottom):
  |       "Route Updated" + "Optimized order applied"
  |       "Undo" button --> restores previous route order
  |       "Done" button --> dismisses toast
  |       Auto-dismisses after 5 seconds
```

---

## Journey 6: Pool Detail & Customer Management

**Actor:** Technician reviewing a specific pool's full details
**Goal:** See chemistry, profit, equipment, history, and customer profile; take action
**Entry Point:** Tap any pool row in PoolListView (NavigationLink)

### Step-by-Step Flow

```
PoolDetailView (pushed onto NavigationStack)
  |
  +-- Navigation title: customer name (.large)
  +-- Toolbar:
  |     - "Edit" button (primaryAction) --> presents EditPoolView sheet
  |     - Export menu (secondaryAction, square.and.arrow.up):
  |       "Export CSV" (tablecells) --> generates per-pool CSV, shows share sheet
  |       "Customer Visit PDF" (doc.richtext) --> generates PDF, shows share sheet
  |       "Email Report to Customer" (envelope) --> generates PDF, opens MFMailComposeViewController
  |         Pre-fills recipient from customer profile email
  |
  +-- CUSTOMER HEADER:
  |     - Address, notes (if any)
  |
  +-- CUSTOMER PROFILE CARD:
  |     - Header: "Customer Profile" + "Edit" button
  |     - Fields: Contact Name, Phone, Email, Gate Access, Arrival Window, Tags
  |     - If empty: "No customer profile details yet."
  |     - "Edit" --> presents CustomerProfileEditorView sheet (Form with Contact + Operations sections)
  |
  +-- LSI SUMMARY CARD:
  |     - "LSI" header
  |     - Large value: "+0.12" (displayFont, color-coded)
  |     - Status label: "Balanced" (semibold, color-coded)
  |
  +-- CHEMISTRY GRID (LazyVGrid):
  |     - pH (purple), Temp (red), Calcium (cyan), Alkalinity (teal), CYA (indigo)
  |     - Each tile: label, value + unit, range status indicator (Low/OK/High)
  |
  +-- CHEMISTRY TREND CHART (if 2+ service events):
  |     - Swift Charts LineMark for pH and LSI (shifted) over last 15 visits
  |     - Reference lines at pH 7.2 and 7.8
  |     - X-axis: date, Y-axis: value
  |
  +-- PROFIT CARD:
  |     - Header: "MONTHLY PROFIT" + "IN THE RED" badge if loss
  |     - Three columns: Fee ($), Chem Cost ($, orange), Profit ($, green/red)
  |
  +-- EQUIPMENT SECTION:
  |     - Header: "Equipment" + count
  |     - Preview of first 3 items with name, type, warranty/service status badges
  |     - NavigationLink: "View All Equipment" --> EquipmentListView (see Journey 8)
  |
  +-- ACTION BUTTONS (large, gloved-hand friendly):
  |     [1] "Quick Log Service" (checkmark.circle.fill, primaryActionColor)
  |         --> presents QuickLogView sheet
  |     [2] "Run Dosing Calculator" (drop.fill, secondaryActionColor)
  |         --> presents DosingCalculatorView sheet (with pool pre-loaded)
  |     [3] "Chemical Usage History" (flask.fill, systemGray5)
  |         --> NavigationLink to ChemicalUsageHistoryView
  |
  +-- PHOTO GALLERY (if any service events have photos):
  |     - Header: "PHOTOS"
  |     - Horizontal scroll of thumbnails with date captions
  |     - Tap thumbnail --> full-screen photo viewer sheet with "Done" dismiss
  |
  +-- SERVICE HISTORY PREVIEW:
        - Header: "Service History" + "X total" count
        - Last 6 events: date, time, LSI badge, pH, chemical cost, camera icon
        - NavigationLink: "View Full History" --> ServiceHistoryView
```

### Chemical Usage History (ChemicalUsageHistoryView)

Accessed via "Chemical Usage History" button in PoolDetailView:

```
ChemicalUsageHistoryView (pushed onto NavigationStack)
  |
  +-- Navigation title: "Chemical Usage" (.large)
  |
  +-- USAGE SUMMARY card:
  |     Total Spent ($) | Avg / Visit ($) | Visits (count)
  |
  +-- TOP CHEMICALS card:
  |     Up to 5 chemicals sorted by total cost descending
  |     Each: colored dot + name + total quantity + total cost
  |
  +-- COST TREND chart (if 2+ visits with doses):
  |     BarMark chart showing per-visit chemical cost over time
  |
  +-- VISIT DETAILS:
        Per-visit breakdown with date, total cost, individual dose details
```

### Service History (ServiceHistoryView)

Accessed via "View Full History" in PoolDetailView:

```
ServiceHistoryView (pushed onto NavigationStack)
  |
  +-- Navigation title: "Service History" (.inline)
  +-- Searchable by notes: "Search notes..."
  +-- Full list of all service events (newest first)
  +-- Each row: date, time, LSI badge, pH, chemical cost, camera icon
  +-- SWIPE ACTIONS:
  |     - Swipe LEFT: "Delete" (destructive) with confirmation alert
  |     - Swipe RIGHT: "Edit" (blue, pencil) --> presents EditServiceEventView sheet
  +-- CONTEXT MENU: Edit + Delete
  +-- EditServiceEventView: Form with reading inputs, LSI preview, notes, timestamp display
        Save updates event + pool readings if most recent event
```

---

## Journey 7: Profit Review (Analytics)

**Actor:** Business owner or technician reviewing financial health
**Goal:** Identify money-losing pools and take corrective action
**Duration:** ~2-5 minutes
**Gating:** Pro subscription required (checked when tab is selected)

### Step-by-Step Flow

```
Tap "Analytics" tab
  |
  +-- SUBSCRIPTION CHECK:
  |     canAccess(.analytics, poolCount: allPools.count)
  |     If free tier: tab selection is BLOCKED
  |     Presents SubscriptionPaywallSheet(context: .analyticsTab)
  |       Title: "Unlock Analytics"
  |       Subtitle: "See money losers first and act faster with premium analytics."
  |     User must upgrade or close paywall (returns to previous tab)
  |
  v (Pro users only)
ProfitDashboardView
  |
  +-- Navigation title: "Analytics" (.large)
  |
  +-- PERIOD PICKER (segmented):
  |     [30 Days] [60 Days] [90 Days]
  |
  +-- TRIAGE CONTROLS:
  |     - Sort menu (arrow.up.arrow.down.circle): "Sort: [current mode]"
  |       Options:
  |         "Money Losers First" (default)
  |         "Worst Margin First"
  |         "Highest Chem Spend"
  |         "Alphabetical"
  |     - Toggle: "Only Money Losers"
  |       (money loser = chem cost > 30% of monthly fee)
  |
  +-- SUMMARY CARD:
  |     - Header: "30-DAY SUMMARY" (or 60/90)
  |     - Revenue (blue) | Chem Spend (orange) | Net Profit (green/red)
  |     - Warning: "X Money Loser(s)" with exclamationmark.triangle.fill (red)
  |
  +-- PER-POOL BREAKDOWN:
        Each pool card shows:
        |
        +-- Customer name + "MONEY LOSER" badge (red capsule, if applicable)
        +-- Fee (dollarsign.circle) + Chem cost (flask, orange)
        +-- Profit amount (title3, green/red)
        +-- Money loser cards get red-tinted background
        |
        +-- ACTION BUTTONS (per pool):
              [1] "Open Detail" (info.circle, .bordered) --> NavigationLink to PoolDetailView
              [2] "Run Dosing" (drop.fill, .bordered) --> presents DosingCalculatorView sheet
              [3] "Quick Log" (checkmark.circle, .borderedProminent) --> presents QuickLogView sheet
```

---

## Journey 8: Equipment Management

**Actor:** Technician tracking pool equipment for maintenance scheduling
**Goal:** Record equipment, track warranty and service dates, identify overdue items
**Entry Point:** "View All Equipment" link in PoolDetailView

### Step-by-Step Flow

```
PoolDetailView --> "View All Equipment"
  |
  v
EquipmentListView (pushed onto NavigationStack)
  |
  +-- Navigation title: "Equipment" (.inline)
  |
  +-- Toolbar: "+" button (plus icon) --> presents EditEquipmentView(existingEquipment: nil) sheet
  |
  +-- EQUIPMENT LIST:
  |     - Sorted alphabetically by name
  |     - Each row:
  |       Name (.subheadline, medium weight)
  |       Type + manufacturer (caption, secondary)
  |       Status badges (right-aligned):
  |         "Warranty Expired" (red capsule) -- if warrantyExpiryDate < now
  |         "Service Overdue" (orange capsule) -- if nextServiceDate < now
  |     - Tap row --> presents EditEquipmentView(existingEquipment: item) sheet
  |     - Swipe to delete: .onDelete with SwiftData persistence
  |
  +-- EMPTY STATE: "No equipment tracked yet."
  |
  v
EditEquipmentView (sheet)
  |
  +-- Navigation title: "Add Equipment" / "Edit Equipment" (.inline)
  +-- Cancel / Save toolbar buttons
  +-- Save disabled if name is empty
  |
  +-- FORM SECTIONS:
  |     "Equipment Details":
  |       - Name (TextField)
  |       - Type (Picker: pump, filter, heater, cleaner, chlorinator, other)
  |       - Manufacturer (TextField)
  |       - Model Number (TextField)
  |       - Serial Number (TextField)
  |
  |     "Dates" (each with Toggle to enable/disable):
  |       - Install Date (DatePicker, if toggled on)
  |       - Warranty Expiry (DatePicker, if toggled on)
  |       - Last Service Date (DatePicker, if toggled on)
  |       - Next Service Date (DatePicker, if toggled on)
  |
  |     "Notes":
  |       - TextEditor (min height 60)
  |
  +-- SAVE: creates or updates Equipment in SwiftData, hapticSuccess(), dismiss
```

---

## Journey 9: Subscription & Paywall

**Actor:** Free-tier user hitting a premium feature limit
**Goal:** Understand Pro benefits, start trial or subscribe
**Duration:** ~1-2 minutes

### Paywall Trigger Points

The paywall is presented as a sheet (`SubscriptionPaywallSheet`) with context-specific messaging:

| Context | Trigger | Title | Subtitle |
|---------|---------|-------|----------|
| `analyticsTab` | Tap Analytics tab (free tier) | "Unlock Analytics" | "See money losers first and act faster with premium analytics." |
| `optimizeRoute` | Tap optimize button (free tier) | "Unlock Route Optimization" | "Preview faster stop order and save drive time each route day." |
| `poolCapReached` | Add 6th pool (free tier, cap = 5) | "Upgrade for Unlimited Pools" | "Free tier includes up to 5 pools. Upgrade to add more customers." |
| `backupRestore` | Tap backup/restore (free tier) | "Unlock Full Backup & Restore" | "Protect your full account with premium backup and restore." |
| `settingsUpgrade` | Tap upgrade in Settings | "Upgrade to PoolFlow Pro" | "Start your 7-day free trial, then choose monthly or annual." |
| `cloudSync` | Tap "Upgrade to Pro" in iCloud section | "Unlock iCloud Sync" | "Sync your pool data across all your devices with iCloud." |

### Step-by-Step Flow

```
User hits gated feature
  |
  +-- Tab selection is blocked (Analytics) OR action is prevented (Optimize, Add Pool, Backup)
  |
  v
SubscriptionPaywallSheet (presented as .sheet)
  |
  +-- Navigation title: "PoolFlow Pro" (.inline)
  +-- "Close" button (cancellationAction)
  |
  +-- Context-specific title + subtitle displayed at top
  |
  +-- PAYWALL BODY (one of three states):
        |
        +-- [1] RevenueCat PaywallView (if billing available):
        |     - RevenueCatUI native paywall with product offerings
        |     - Displays plans (poolflow_pro_monthly, poolflow_pro_annual)
        |     - 7-day free trial offer
        |     - Purchase flow handled by RevenueCat
        |     - On disappear: refreshes customer info + closes
        |
        +-- [2] Billing Unavailable view:
        |     - "Billing Unavailable" (exclamationmark.triangle.fill, orange)
        |     - Message: "RevenueCat is not configured for this build..."
        |     - "Free-tier features remain available."
        |
        +-- [3] UI Test Stub (debug only):
              - "Simulate Upgrade" button --> forces paid tier
              - Only shown when -uiTestUseStubPaywall launch argument present

Post-purchase:
  - SubscriptionManager.refreshCustomerInfo() updates:
    isPremiumActive, subscriptionTier, isTrialActive, entitlementExpirationDate
  - If trial active: schedules trial expiration reminder notification
  - Gated features become accessible immediately
```

### Settings Subscription Management

```
Settings --> "Subscription" section:
  |
  +-- Current Plan: "Free" / "Trial" / "Pro" (color-coded)
  +-- Trial Ends / Renews date (if applicable)
  +-- Billing unavailable warning (if RevenueCat not configured)
  +-- "Start 7-Day Free Trial / Upgrade to Pro" button
  |     (label changes to "Manage Plan" if already Pro)
  +-- "Restore Purchases" button (disabled if billing unavailable)
  +-- "Manage Subscription" button --> opens Apple subscription management URL
  +-- "Refresh Subscription Status" button
  +-- Info text: "Free tier includes up to 5 pools. Pro unlocks unlimited pools,
        analytics, route optimization, and full backup/restore."
```

### Free Tier Limits

| Feature | Free | Pro |
|---------|------|-----|
| Pools | Up to 5 | Unlimited |
| Analytics tab | Blocked | Full access |
| Route optimization | Blocked | Full access |
| Backup & restore | Blocked | Full access |
| iCloud sync | Disabled | Automatic (CloudKit) |

---

## Journey 10: Backup & Restore

**Actor:** Technician protecting data or migrating devices
**Goal:** Create a complete backup archive and restore from it
**Duration:** ~1-2 minutes per operation
**Gating:** Pro subscription required + `featureBackupRestoreEnabled` toggle must be on

### Backup Flow

```
Settings --> "Data & Reports" section
  |
  +-- Prerequisite: "Enable Backup & Restore (Beta)" toggle ON in Workflow section
  |     (feature flag: featureBackupRestoreEnabled)
  |
  +-- Tap "Export Full Backup (.zip)" (archivebox icon)
  |     |
  |     +-- Subscription check: guardPremiumAccess(for: .backupRestore)
  |     |     If free tier: presents paywall with context .backupRestore
  |     |
  |     +-- DataExportService.exportFullBackup() generates ZIP containing:
  |     |     manifest.json (schema version, timestamp, app version, record counts)
  |     |     pools.json
  |     |     service_events.json
  |     |     chemical_doses.json
  |     |     inventory.json
  |     |     customer_profiles.json (from CustomerProfileViewModel.exportAllProfiles)
  |     |     equipment.json
  |     |     media/*.bin (photo data)
  |     |
  |     +-- ActivityShareSheet presented with ZIP file URL
  |           User can: Save to Files, AirDrop, email, cloud storage
```

### Restore Flow

```
Settings --> Tap "Restore from Backup (.zip)" (arrow.clockwise.doc icon)
  |
  +-- Subscription check (same as backup)
  |
  +-- File importer: .fileImporter(allowedContentTypes: [.zip])
  |     User selects .zip backup file from Files
  |
  +-- File copied to temp directory for safe access
  |
  +-- DataImportService.previewFullBackup() parses manifest and validates:
  |     - Schema version compatibility check
  |     - Record counts extracted
  |
  v
BackupRestorePreviewSheet (presented as .sheet)
  |
  +-- Navigation title: "Restore Preview" (.inline)
  |
  +-- "Backup" section:
  |     - Created: [date/time]
  |     - Schema Version: [number]
  |     - Compatibility: "Supported" (green) / "Unsupported" (red)
  |
  +-- "Record Counts" section:
  |     Pools: X, Service Events: Y, Chemical Doses: Z,
  |     Inventory: N, Profiles: M, Equipment: P, Media Files: Q
  |
  +-- "Warnings" section (if any)
  |
  +-- Toolbar:
        "Cancel" --> cleans up temp file, dismisses
        "Apply Restore" (confirmationAction, disabled if incompatible)
          |
          +-- Confirmation dialog: "Replace all current records?"
          |     "This replaces pools, service history, inventory, and customer
          |      profile data with backup contents."
          |     "Replace and Restore" (destructive) / "Cancel"
          |
          +-- ON APPLY:
                1. DataImportService.applyFullBackup() runs
                2. All existing data replaced with backup contents
                3. Summary alert: "Restored X pools, Y service events, Z doses,
                   N inventory items, M profiles, P equipment items."
                4. Notifications rescheduled for restored data
```

### Emergency Recovery (StoreRecoveryView)

If the SwiftData ModelContainer fails to open on launch:

```
StoreRecoveryView (replaces normal app UI)
  |
  +-- Navigation title: "Recovery"
  +-- Warning: "Couldn't Open Local Database" (exclamationmark.triangle.fill, orange)
  +-- Message: "PoolFlow could not open your local data store..."
  |
  +-- Three actions:
        [1] "Restore from Backup (.zip)" (.borderedProminent)
            --> file importer for .zip, confirmation dialog, then restore
        [2] "Reset Local Database" (.bordered)
            --> confirmation dialog: "Reset Database" (destructive)
            --> removes store files, creates fresh container
        [3] "Retry" (.bordered)
            --> re-attempts store opening
```

---

## Journey 11: Data Import & Export

**Actor:** Technician importing customer data from spreadsheets or exporting for analysis
**Goal:** Bulk import pools from CSV, export data in CSV/PDF formats

### CSV Import Flow

```
Settings --> "Data & Reports" section
  |
  +-- Tap "Import Data (CSV)" (square.and.arrow.down icon)
  |
  +-- File importer: .fileImporter(allowedContentTypes: [.commaSeparatedText, .plainText])
  |     User selects .csv file from Files
  |
  +-- DataImportService.stageCustomersCSV() parses and validates:
  |     - Column detection and mapping
  |     - Match against existing pools by normalized name+address
  |
  v
ImportPreviewSheet (presented as .sheet)
  |
  +-- Navigation title: "Import Preview" (.inline)
  |
  +-- "Preview" section:
  |     Creates: X (new pools)
  |     Updates: Y (matched existing)
  |     Skips: Z (validation failures)
  |
  +-- "Issues" section (if any, up to 50):
  |     Row number + field + message (red for errors, secondary for warnings)
  |
  +-- Toolbar:
        "Cancel" --> dismisses, no changes
        "Apply" --> confirmation dialog:
          "Apply this import?"
          "This will upsert customers by normalized name and address."
          |
          +-- Pool cap check: if free tier and (existing + creates) > 5:
          |     presents paywall with context .poolCapReached
          |
          +-- ON APPLY:
                DataImportService.apply(strategy: .upsertByNormalizedNameAddress)
                Summary alert: "Created X, updated Y, skipped Z."
```

### Export Options (from Settings)

```
"Data & Reports" section:
  |
  +-- "Export All Pools (CSV)" --> CSV file with all pool data --> share sheet
  +-- "Export Service History (CSV)" --> CSV of all service events --> share sheet
  +-- "Export Inventory (CSV)" --> CSV of chemical inventory --> share sheet
  +-- "Monthly Performance (PDF)" --> PDF report of all pools --> share sheet
  +-- "Download Import Template (CSV)" --> blank CSV template --> share sheet
  +-- "Clear All App Data" (destructive):
        Confirmation dialog: "Clear All App Data?"
        "This clears pools, service history, and inventory entries.
         Default inventory is re-added automatically. App preferences and toggles are kept."
        "Clear All App Data" (destructive) / "Cancel"
        Summary alert on completion
```

### Export Options (from PoolDetailView)

```
PoolDetailView toolbar --> Export menu (square.and.arrow.up):
  |
  +-- "Export CSV" --> per-pool CSV --> share sheet
  +-- "Customer Visit PDF" --> PDF visit report --> share sheet
  +-- "Email Report to Customer" --> PDF generated, MFMailComposeViewController opens
        Pre-fills: subject, recipient (from customer profile email), HTML body, PDF attachment
```

---

## Journey 12: Settings & Configuration

**Actor:** User customizing their PoolFlow experience
**Goal:** Adjust defaults, appearance, workflow, notifications, and view data health

### Settings View Sections

```
SettingsView (Form within NavigationStack)
  |
  +-- "Defaults" section:
  |     - Default Pool Volume: slider with value display (unit-aware)
  |
  +-- "Appearance" section:
  |     - Theme: [System] [Light] [Dark] (segmented Picker)
  |     - Language: System Default / English / Espanol / Francais / Portugues (Brasil) / Deutsch
  |
  +-- "Chemical Inventory" section: (see Journey 13)
  |
  +-- "Workflow" section:
  |     - Toggle: "Confirm Before Quick Log Save"
  |     - Toggle: "Enable Backup & Restore (Beta)"
  |     - Picker: "Route Optimization Goal" (objective selection)
  |     - Button: "Replay Onboarding" (arrow.clockwise.circle)
  |       --> sets forceShowOnboarding = true --> triggers OnboardingFlowView
  |
  +-- "Subscription" section: (see Journey 9)
  |
  +-- "Data & Reports" section: (see Journey 11)
  |
  +-- "Notifications" section:
  |     - Toggle: "Enable Notifications" (requests OS authorization when turned on)
  |     - DatePicker: "Route Summary Time" (hour:minute)
  |     - Toggle: "Morning Route Summary"
  |     - Toggle: "Low Stock for Tomorrow"
  |     - Toggle: "Weekly Digest"
  |     - Button: "Reschedule Notifications"
  |     - All notification toggles disabled if master toggle is off
  |
  +-- "Data Health" section:
  |     - Missing Coordinates: count (orange if > 0)
  |     - Missing Service Fee: count (orange if > 0)
  |     - Stale Service (>35d): count (orange if > 0)
  |
  +-- "iCloud Sync" section:
  |     - If Pro: shows sync status + iCloud availability
  |     - If Free: "Upgrade to Pro to enable iCloud sync across devices."
  |       + "Upgrade to Pro" button --> paywall
  |
  +-- "About" section:
        - Version: [CFBundleShortVersionString]
        - Build: [CFBundleVersion]
        - Privacy Policy (external link: poolflow.app/privacy)
        - Terms of Service (external link: poolflow.app/terms)
```

---

## Journey 13: Chemical Inventory Management

**Actor:** Technician tracking chemical stock levels
**Goal:** Maintain accurate inventory, receive low-stock warnings
**Entry Point:** Settings --> "Chemical Inventory" section

### Step-by-Step Flow

```
Settings --> Chemical Inventory section
  |
  +-- Section header: "Chemical Inventory" + "+" button (plus.circle.fill)
  |
  +-- LOW-STOCK WARNING (if any items below threshold):
  |     exclamationmark.triangle.fill + "X items running low" (orange)
  |
  +-- INVENTORY LIST (pre-seeded on first launch with 7 default chemicals):
  |     Each row:
  |     - Low-stock indicator (exclamationmark.triangle.fill, orange) if applicable
  |     - Chemical name + type badge
  |     - Cost per unit (unit-aware: $/oz or $/g or $/mL)
  |     - Current stock + "in stock" (orange if low)
  |     - Tap row --> NavigationLink to EditInventoryItemView(existingItem: item)
  |     - Swipe to delete (.onDelete)
  |
  +-- "+" BUTTON --> presents EditInventoryItemView(existingItem: nil) as sheet
  |
  v
EditInventoryItemView (sheet for new, pushed via NavigationLink for existing)
  |
  +-- Form fields: name, chemical type picker, cost per ounce,
  |     current stock (oz), unit label, concentration, low-stock threshold
  |
  +-- STOCK AUTO-DECREMENTS:
        When QuickLogView saves with confirmed chemical doses,
        ChemicalInventory.currentStockOz is decremented by dose.quantityOz (clamped at 0).
        If undo is triggered within 5 seconds, stock is restored.
        When stock drops below threshold: isLowStock becomes true,
        low-stock notification scheduled (if enabled), badge appears on Settings tab.
```

---

## Screen Flow Diagrams

### Primary Navigation Architecture

```
PoolFlowApp
  |
  +-- [.loading] --> "Opening PoolFlow Data" spinner
  +-- [.recovery] --> StoreRecoveryView (retry / reset / restore)
  +-- [.ready] --> ContentView
        |
        +-- [iPhone] TabView
        |     |
        |     +-- Tab 1: PoolListView (NavigationStack)
        |     |     +-- PoolDetailView
        |     |     |     +-- EditPoolView (sheet)
        |     |     |     +-- QuickLogView (sheet, .medium/.large)
        |     |     |     +-- DosingCalculatorView (sheet)
        |     |     |     +-- ChemicalUsageHistoryView (push)
        |     |     |     +-- EquipmentListView (push)
        |     |     |     |     +-- EditEquipmentView (sheet)
        |     |     |     +-- ServiceHistoryView (push)
        |     |     |     |     +-- EditServiceEventView (sheet)
        |     |     |     +-- ActivityShareSheet (sheet)
        |     |     |     +-- MailComposeView (sheet)
        |     |     |     +-- Photo viewer (sheet)
        |     |     |     +-- CustomerProfileEditorView (sheet)
        |     |     +-- AddPoolView (sheet)
        |     |     +-- QuickLogView (sheet, from swipe/context)
        |     |     +-- Optimization Preview (sheet)
        |     |
        |     +-- Tab 2: DosingCalculatorView (NavigationStack)
        |     |     +-- Pool Picker (sheet)
        |     |
        |     +-- Tab 3: ProfitDashboardView (NavigationStack) [Pro gated]
        |     |     +-- PoolDetailView (push)
        |     |     +-- DosingCalculatorView (sheet)
        |     |     +-- QuickLogView (sheet)
        |     |
        |     +-- Tab 4: SettingsView (NavigationStack)
        |           +-- EditInventoryItemView (push for existing, sheet for new)
        |           +-- File importers (CSV, ZIP)
        |           +-- Import/Backup preview sheets
        |           +-- ActivityShareSheet (share exports)
        |
        +-- [iPad] NavigationSplitView
              Sidebar: PoolFlow title + 4 sidebar items
              Detail: same views as iPhone tabs
        |
        +-- [Overlay] OnboardingFlowView (.fullScreenCover)
        +-- [Sheet] Notification Primer
        +-- [Sheet] SubscriptionPaywallSheet (context-dependent)
```

### Quick Log Data Flow

```
QuickLogView opens
  |
  v
pool.latestReadings() --> pre-fills pH, Temp, Ca, Alk, CYA
  |
  v
User adjusts readings --> LSICalculator.calculate() runs live
  |                        DosingEngine.recommend() runs live
  v
User confirms/unconfirms chemical doses
  |
  v
Tap "Log & Done"
  |
  +-- [Optional] Confirmation dialog (if quickLogConfirmBeforeSave on)
  |
  v
Save sequence:
  ServiceEvent created --> ChemicalDose records created
  --> Inventory decremented --> Pool readings updated
  --> pool.recalculateLSI() --> quickLogSuccessCount++
  |
  v
Undo toast (5-second window)
  |
  +-- "Undo" --> reverse all operations
  +-- "Done" or timeout --> dismiss sheet
```

### Subscription Decision Flow

```
User taps gated feature
  |
  v
SubscriptionManager.canAccess(feature, poolCount) ?
  |
  +-- YES --> proceed normally
  +-- NO --> SubscriptionManager.presentPaywallIfNeeded(context) ?
        |
        +-- YES --> present SubscriptionPaywallSheet
        |     |
        |     +-- RevenueCat PaywallView (purchase/trial)
        |     +-- OR Billing Unavailable notice
        |     +-- "Close" returns to previous state
        |
        +-- NO --> (should not happen in practice)
```

### Onboarding Branching Logic

```
Welcome
  |
  v
Q1: User Type?
  |
  +-- brandNew / migrating / businessOwner
  |
  v
Q2: Feature Focus?
  |
  +-- routeFocus / chemistryFocus / profitFocus
  |   (Pool count question has been removed from the streamlined flow)
  |
  v
Feature Highlights (3-page tour)
  |
  v
Guided Action: Inline Add Pool form (all user types)
  |
  +-- brandNew / nil --> Onboarding complete (intent: .none)
  +-- migrating / businessOwner --> Import Method Selection step
        |
        +-- "Import customer list" --> complete (intent: .openCustomerImport)
        +-- "Restore full backup" --> complete (intent: .openBackupRestore)
        +-- "I'll add pools manually" --> complete (intent: .none)
        +-- "Skip for now" --> complete (intent: .none)
```

---

## Friction Points & Known Limitations

### Data Safety

| Issue | Impact | Severity |
|-------|--------|----------|
| iCloud sync requires Pro + restart | Data not synced until user restarts app after upgrading | **Medium** |
| Backup ZIPs unencrypted | Customer data exposed if backup file shared insecurely | **Medium** |
| Backup/restore behind feature flag | Beta toggle must be manually enabled in Settings > Workflow | **Medium** |
| No automatic backup schedule | User must remember to create backups manually | **Medium** |

### Authentication & Security

| Issue | Impact | Severity |
|-------|--------|----------|
| No authentication layer | Anyone with device access can view all customer data and financials | **Medium** |
| No biometric lock | No Face ID/Touch ID option | **Medium** |
| Customer profiles stored in UserDefaults (JSON) | Gate codes, phone numbers in plaintext | **Low** |

### User Experience

| Issue | Impact | Severity |
|-------|--------|----------|
| Geocoding is async | Coordinates may be missing briefly after pool creation; optimization may fail | **Low** |
| Route optimization requires 2+ pools | New users cannot optimize until they have 2 pools with coordinates | **Low** |
| No undo for pool/event deletion | Only Quick Log saves and route optimization have undo; deletions are permanent | **Medium** |
| Analytics tab blocked entirely on free tier | Users get no preview of analytics value before upgrading | **Low** |
| Photo storage on-device only | Large photo libraries consume significant device storage | **Low** |

### Technical Constraints

| Issue | Impact | Severity |
|-------|--------|----------|
| Single-device without Pro | No multi-device sync on free tier | **Medium** |
| No multi-technician support | Cannot share routes between team members | **Medium** |
| MapKit ETA requires connectivity | Falls back to Haversine (less accurate) offline | **Low** |
| Stale service threshold fixed at 35 days | May not suit monthly-only service schedules | **Low** |

---

## Journey Map Summary

| # | Journey | Entry Point | Primary View | Duration | Gating |
|---|---------|-------------|-------------|----------|--------|
| 1 | First Launch & Onboarding | App install | OnboardingFlowView | 2-3 min | None |
| 2 | Daily Route Workflow | App open | PoolListView | Full day | None |
| 3 | Quick Log Service | Swipe / button | QuickLogView | < 2 min | None |
| 4 | Chemistry Deep-Dive | Calculator tab / button | DosingCalculatorView | 1-2 min | None |
| 5 | Route Optimization | Wand icon | Optimization preview sheet | 15-30 sec | Pro |
| 6 | Pool Detail & Customer Mgmt | Tap pool row | PoolDetailView | 2-5 min | None |
| 7 | Profit Review | Analytics tab | ProfitDashboardView | 2-5 min | Pro |
| 8 | Equipment Management | Pool detail link | EquipmentListView | 1-3 min | None |
| 9 | Subscription & Paywall | Hit feature limit | SubscriptionPaywallSheet | 1-2 min | N/A |
| 10 | Backup & Restore | Settings | Backup/restore flow | 1-2 min | Pro + flag |
| 11 | Data Import & Export | Settings | CSV/PDF flows | 2-5 min | Pool cap |
| 12 | Settings & Configuration | Settings tab | SettingsView | Variable | None |
| 13 | Chemical Inventory | Settings | Inventory section | 1-3 min | None |

---

*This document maps every primary user journey through PoolFlow as implemented in the SwiftUI codebase (v2.1). For feature details, see [03_Feature_Inventory](03_Feature_Inventory.md). For behavioral specifications, see [04_Functional_Scope](04_Functional_Scope.md).*
