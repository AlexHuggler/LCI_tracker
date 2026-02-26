# PoolFlow — Product Strategy

> **Document:** 02_Product_Strategy
> **Version:** 2.1
> **Last Updated:** 2026-02-25
> **Related Docs:** [01_App_Blueprint](01_App_Blueprint.md) | [03_Feature_Inventory](03_Feature_Inventory.md) | [04_Functional_Scope](04_Functional_Scope.md) | [05_Customer_Journeys](05_Customer_Journeys.md)

---

## 1. Mission Statement

**PoolFlow exists to make every pool service technician faster, smarter, and more profitable** -- replacing paper logs, manual Langelier Saturation Index calculations, and scattered spreadsheets with a single offline-first iOS app purpose-built for wet, gloved hands.

The app consolidates water chemistry, route management, dosing calculations, chemical inventory, profit analytics, and service documentation into one tool that works without network connectivity -- because the best pool software is useless if it can't function poolside.

### One-Liner

> *"Know your water. Know your route. Know your money."*

---

## 2. Value Proposition

### The Problem

Pool service technicians today operate with a fragmented toolset:

- **Paper route sheets** that get wet, lost, or illegible in the field
- **Manual LSI calculations** requiring lookup tables, a calculator, and CYA correction math -- a process most techs skip entirely
- **Spreadsheet-based tracking** for chemical costs, customer billing, and service records across multiple files
- **Multiple apps** for route mapping (Apple Maps), note-taking, photo documentation, and inventory tracking
- **No real-time profitability insight** -- techs cannot tell which pools are money losers until end-of-month accounting
- **No dosing guidance** tied to actual inventory costs -- generic charts do not reflect what the tech actually paid for chemicals

### The Solution: All-in-One Field Tool for Solo Pool Techs

PoolFlow consolidates all of these into a single app:

| Capability | What PoolFlow Replaces |
|-----------|----------------------|
| **Real-time LSI calculation** with CYA adjustment | Manual lookup tables + calculator |
| **Chemical dosing recommendations** with cost from actual inventory | Generic dosing charts with no cost context |
| **Sub-2-minute service logging** (QuickLogView with pre-filled readings) | 5-10 minute paper log entries |
| **Route optimization** (nearest-neighbor + 2-opt with MapKit ETA) | Mental route planning or separate mapping apps |
| **Money loser detection** (chemical cost > 30% of service fee) | End-of-month spreadsheet review |
| **Chemical inventory tracking** with low-stock alerts | Guesswork on truck stock levels |
| **Proof-of-service photos** with report sharing | Camera app + separate email workflow |
| **CSV import/export + PDF reports** | Manual data entry across systems |
| **Full offline operation** | Apps that fail without connectivity |

### Key Selling Points (from onboarding feature highlights)

The app's onboarding flow highlights three core pillars:

1. **"Today's Route"** -- "Work your day in order and track completion live. Filter by day, drag to reorder, get one-tap directions, and quick-log service from the route list."
2. **"Smart Water Chemistry"** -- "Real-time LSI calculations and dosing recommendations. Slide readings to watch the LSI index animate. Get chemical recommendations with cost estimates."
3. **"Profit Analytics"** -- "Spot money-loser pools and act fast. Sort by worst margin, highest chemical spend, or money-loser first. Run dosing or open detail directly."

---

## 3. Target Audience

### Primary: Solo Pool Service Technicians

**Profile (derived from onboarding profiling questions):**
- Operates independently, servicing 5-80+ pools per week
- Drives a service truck with chemicals and equipment
- Works outdoors in sun and heat, frequently with wet or gloved hands
- Uses an iPhone as primary mobile device
- Currently uses paper logs, mental route planning, or basic note-taking apps
- Technically comfortable but values tools that "just work" -- minimal training required

**Onboarding segmentation (from `OnboardingFlowViewModel`):**

| User Type | Description | Guided Action |
|-----------|-------------|---------------|
| **Starting fresh** (`brandNew`) | "I'm starting fresh -- no customer list yet" | Inline add-first-pool form |
| **Bringing customers** (`migrating`) | "I have customers to bring over" | CSV import prompt (or inline add for small counts) |
| **Managing techs** (`businessOwner`) | "I manage techs and want analytics" | CSV import with analytics-ready callout |

**Pool count segmentation (deprecated in current onboarding flow):**

The `PoolCountBracket` enum (`small`, `medium`, `large`) is still defined in `OnboardingFlowViewModel` but the pool count question has been removed from the streamlined onboarding path. The `persistProfile()` method explicitly clears any stored pool count value. Pool count segmentation is instead inferred organically from actual pool additions and the free-tier 5-pool cap.

**Feature focus priorities (from onboarding):**

| Focus | Description | First Feature Highlighted |
|-------|-------------|--------------------------|
| **Route organized** (`routeFocus`) | "Getting my route organized" | Route tab, day picker, drag-to-reorder |
| **Water chemistry** (`chemistryFocus`) | "Tracking water chemistry" | LSI Calculator, dosing recommendations |
| **Profit per pool** (`profitFocus`) | "Seeing my profit per pool" | Analytics dashboard, money loser detection |

### Secondary: Small Pool Service Companies (2-5 Technicians)

**Profile:**
- Owner-operator with 1-4 additional technicians
- Manages 50-200+ pools across multiple routes
- Needs consistent service quality, standardized reporting, and business analytics
- The `businessOwner` onboarding path targets this segment directly

**Value Delivered (current):**
- Standardized service logging with proof-of-service photos
- PDF customer visit reports and monthly performance reports
- Per-pool profitability analysis with triage sorting
- Chemical inventory tracking with low-stock alerts
- CSV import for bulk onboarding of existing customer lists
- Full backup/restore for data preservation

**Current Gaps:**
- No multi-technician or team management features
- No shared routes or centralized management dashboard
- iCloud sync exists but does not support multi-user scenarios

### Tertiary: Pool Service Business Owners (Management Focus)

**Profile:**
- May not service pools directly; focused on business profitability and customer retention
- Needs aggregate analytics and reporting tools

**Value Delivered:**
- Profit dashboard with configurable 30/60/90-day billing periods
- Four sort modes: Money Losers First, Worst Margin First, Highest Chem Spend, Alphabetical
- Money loser toggle filter for focused triage
- CSV/PDF export for accounting integration
- Equipment tracking with warranty and maintenance scheduling

---

## 4. Market Differentiators

### 4.1 LSI Calculator with Integrated Dosing Engine

PoolFlow implements the full Langelier Saturation Index formula with:

- **Industry-standard lookup table interpolation** for temperature, calcium hardness, alkalinity, and TDS factors (source: APSP tables)
- **CYA correction**: Adjusted Alkalinity = Total Alkalinity - (CYA / 3)
- **Three-zone classification**: Corrosive (LSI < -0.3), Balanced (-0.3 to +0.3), Scale-Forming (> +0.3)
- **Live recalculation** as any input slider is adjusted -- the LSI value animates in real time with `contentTransition(.numericText)`

The dosing engine then translates LSI deviations into prioritized, actionable chemical recommendations:

- pH adjustment is always step 1 (fastest acting, most impactful)
- Quantities are calculated per 10,000 gallons, scaled to actual pool volume
- Costs come from the technician's actual chemical inventory prices, with industry-average fallbacks
- Output is in field-practical measurements: ounces, pounds, or gallons

**Differentiator:** Most competing pool apps either skip LSI entirely, use simplified formulas without CYA correction, or provide generic dosing charts without cost tracking.

### 4.2 Profit Analytics with Money Loser Detection

A pool is flagged as a **money loser** when chemical costs exceed 30% of the monthly service fee over the selected billing period. The `ProfitDashboardView` provides:

- **Aggregate summary**: Total revenue, total chemical spend, net profit
- **Per-pool breakdown**: Fee, chem cost, profit, money loser badge
- **Four triage sort modes**: Money Losers First, Worst Margin First, Highest Chem Spend, Alphabetical
- **Money loser toggle**: Filter to show only problem pools
- **Direct action**: "Run Dosing", "Quick Log", and "Open Detail" buttons on each pool card
- **Configurable periods**: 30, 60, and 90-day billing windows

**Differentiator:** No other pool service app ties per-pool chemical usage logs to service fees for real-time profitability analysis.

### 4.3 Wet-Hand UX (Glove-Friendly Design)

The entire UI is designed for technicians with wet or gloved hands, codified in `Theme.swift`:

| Design Decision | Implementation |
|----------------|----------------|
| **56pt primary action buttons** | `Theme.buttonHeight = 56` (above Apple's 44pt minimum) |
| **Large touch targets** | `minTouchTarget = 44pt`, `dayChipSize = 56pt`, `rowActionHitSize = 56pt` |
| **Large typography** | `displayFont = 48pt bold`, `heroFont = 64pt bold`, `actionFont = title3 bold` |
| **Minimal text entry** | Sliders and +/- steppers for chemistry adjustments instead of typing |
| **Pre-filled readings** | QuickLogView pre-populates from last service visit -- just tap "Log & Done" |
| **Haptic feedback** | Pre-warmed `UINotificationFeedbackGenerator` and `UIImpactFeedbackGenerator` for status changes |
| **One-tap directions** | Directions button on every pool row opens Apple Maps with driving directions |
| **Rounded corner system** | `cornerRadius = 14pt`, `cardCornerRadius = 16pt`, `tileCornerRadius = 12pt` |

**Differentiator:** Generic CRM and route tools use standard 44pt touch targets and text-heavy forms. PoolFlow is purpose-built for outdoor field use.

### 4.4 Offline-First Architecture (SwiftData + CloudKit)

PoolFlow has **zero network dependencies for core functionality**:

- All data persisted locally in SwiftData (SQLite-backed)
- LSI calculation, dosing, route optimization, profit analysis -- all run locally
- MapKit ETAs are the only optional network feature, with Haversine distance fallback when offline
- iCloud sync via CloudKit is available for Pro subscribers but not required

**Why this matters:** Pool technicians frequently work in backyards with poor cellular reception, gated communities with limited Wi-Fi, rural properties outside coverage areas, and equipment rooms without signal. An app that requires connectivity is fundamentally broken for this use case.

### 4.5 Route Optimization with Travel Time Estimation

The `RouteOptimizationEngine` uses a two-phase algorithm:

1. **Nearest-neighbor seeding** -- builds an initial route by greedily selecting the closest unvisited pool
2. **2-opt improvement** -- iteratively reverses route segments to reduce total travel time (up to 2 passes)

Travel time estimation uses a `HybridTravelTimeEstimator`:
- **Primary**: MapKit ETA via `MKDirections` when network is available
- **Fallback**: Haversine great-circle distance converted to drive time

Three optimization objectives: Minimize Drive Time, Minimize Drive Distance, Balanced (weighted displacement penalty).

Results are presented in a preview sheet showing current vs. optimized order with estimated time saved, and an undo toast allows instant rollback.

### 4.6 Competitive Positioning Summary

| Capability | PoolFlow | Paper Logs | Generic Pool Apps | Business CRM (Jobber, etc.) |
|-----------|----------|------------|-------------------|-----------------------------|
| LSI calculation | Real-time with CYA correction | Manual lookup tables | Basic (no CYA) | None |
| Dosing recommendations | Cost-linked from actual inventory | None | Generic charts | None |
| Route optimization | Algorithmic (NN + 2-opt) | Manual/mental | None | Some (basic) |
| Per-pool profit tracking | Real-time money loser detection | None | None | Aggregate only |
| Offline operation | Full -- zero network required | Full (paper) | Partial | None (cloud-dependent) |
| Service logging speed | < 2 minutes (pre-filled) | 5-10 minutes | 3-5 minutes | 5+ minutes |
| Glove-friendly UI | 56pt buttons, sliders, haptics | N/A | Standard 44pt | Standard 44pt |
| Chemical inventory | Integrated with auto-decrement | Manual tracking | Separate | Separate |
| Photo proof | In-workflow capture | Camera app | Some | Some |
| Data backup | Full ZIP archive + iCloud sync | None | Cloud-dependent | Cloud-dependent |
| Equipment tracking | Per-pool with warranty/service dates | None | None | Some |

---

## 5. Monetization Strategy

### Subscription Architecture

PoolFlow uses **RevenueCat** for subscription management, with a single `"PoolFlow Premium"` entitlement gating premium features.

**Configuration (from `SubscriptionManager.swift`):**
- RevenueCat API key loaded from `Info.plist` (`RevenueCatAPIKey` or `REVENUECAT_API_KEY`)
- Entitlement ID: `"PoolFlow Premium"`
- Paywalls rendered via `SubscriptionPaywallSheet` (wraps `RevenueCatUI.PaywallView` for live builds, with a stub fallback for UI testing and billing-unavailable states)
- Free-tier graceful fallback when RevenueCat is not configured or API key is missing

### Subscription Tiers

| Tier | State | Access |
|------|-------|--------|
| **Free** | Default, no purchase | Up to 5 pools, basic route view, LSI calculator, service logging, chemical inventory |
| **Trial** | 7-day free trial (auto-enrolled on first subscription) | Full Pro access for 7 days |
| **Pro (Paid)** | Monthly or Annual subscription | Unlimited pools, analytics, route optimization, full backup/restore, iCloud sync |

### Pricing (from `PoolFlow.storekit`)

| Product | Product ID | Price | Billing | Trial |
|---------|------------|-------|---------|-------|
| **PoolFlow Pro Monthly** | `Pool_01` | $29.99/mo | Monthly recurring | 7-day free trial |
| **PoolFlow Pro Annual** | `Pool_02` | $299.99/yr | Annual recurring | 7-day free trial |

Both products are in the `poolflow_pro` subscription group (ID: `POOLFLOW_PRO_GROUP`). The annual plan saves ~$60/year compared to monthly billing ($299.99 vs. $359.88).

### Free Tier Limitations

The free tier is deliberately generous for initial adoption:

| Limit | Value | Source |
|-------|-------|--------|
| **Pool cap** | 5 pools maximum | `SubscriptionManager.freePoolCap = 5` |
| **Analytics** | Locked (paywall) | `PremiumFeature.analytics` |
| **Route optimization** | Locked (paywall) | `PremiumFeature.routeOptimization` |
| **Full backup/restore** | Locked (paywall) | `PremiumFeature.backupRestore` |
| **iCloud sync** | Locked (paywall) | `PaywallContext.cloudSync` |

**Free features (no restrictions):**
- LSI Calculator with full dosing recommendations
- Service logging via QuickLogView (for pools within the 5-pool cap)
- Route view with day picker, drag-and-drop reorder, one-tap directions
- Chemical inventory management with low-stock alerts
- Equipment tracking per pool
- CSV export (pools, service history, inventory)
- PDF reports (customer visit, monthly performance)
- CSV import (with pool cap enforcement)
- Customer profile management (contact info, gate access, tags)
- Notifications (morning route summary, low stock, weekly digest)
- Localization (English, Spanish, French, Portuguese, German)

### Paywall Contexts and Conversion Points

The app presents contextual paywalls at six distinct moments:

| Context | Trigger | Paywall Title | Paywall Subtitle |
|---------|---------|--------------|-----------------|
| `analyticsTab` | User taps Analytics tab | "Unlock Analytics" | "See money losers first and act faster with premium analytics." |
| `optimizeRoute` | User taps Optimize Route button | "Unlock Route Optimization" | "Preview faster stop order and save drive time each route day." |
| `backupRestore` | User taps backup or restore actions | "Unlock Full Backup & Restore" | "Protect your full account with premium backup and restore." |
| `poolCapReached` | User adds 6th pool or imports beyond cap | "Upgrade for Unlimited Pools" | "Free tier includes up to 5 pools. Upgrade to add more customers." |
| `settingsUpgrade` | User taps upgrade in Settings | "Upgrade to PoolFlow Pro" | "Start your 7-day free trial, then choose monthly or annual." |
| `cloudSync` | User taps iCloud sync upgrade prompt | "Unlock iCloud Sync" | "Sync your pool data across all your devices with iCloud." |

### Trial Mechanics

- **Duration**: 7 days (configured as `P1W` introductory offer with `paymentMode: "free"`)
- **Activation**: Automatic on first subscription purchase
- **Notification**: Trial expiring reminder sent 1 day before expiration via local notification ("Your PoolFlow Pro trial ends tomorrow. Upgrade now to keep unlimited pools, analytics, and route optimization.")
- **Post-trial**: Falls back to free tier if not converted

### Subscription Management

- **Settings section** displays current plan (Free/Trial/Pro), expiration/renewal date, and billing status
- **"Start 7-Day Free Trial / Upgrade to Pro"** button in Settings (changes to "Manage Plan" when subscribed)
- **"Restore Purchases"** button for device transfers
- **"Manage Subscription"** links to Apple's subscription management page
- **"Refresh Subscription Status"** for manual sync with RevenueCat

---

## 6. Growth Opportunities

### Near-Term (Implemented or In Progress)

#### 6.1 iCloud Sync via CloudKit (Implemented -- Pro Feature)

- SwiftData `ModelConfiguration` with `cloudKitDatabase: .automatic` for Pro users
- `CloudSyncMonitor` tracks sync status (Idle, Syncing, Synced, Error, Account Unavailable)
- Sync activates on app launch for Pro subscribers; requires app restart after initial Pro upgrade
- Enables multi-device use (technician iPhone in the field, owner iPad at the office)

#### 6.2 Equipment Tracking (Implemented)

- `Equipment` model per pool: pump, filter, heater, cleaner, salt system, automation, light, cover, other
- Tracks manufacturer, model number, serial number, install date, warranty expiry, service dates
- Computed properties: `isWarrantyExpired`, `isServiceOverdue`
- Included in full backup/restore
- Foundation for future maintenance scheduling and parts ordering

#### 6.3 Customer Profiles (Implemented)

- `CustomerProfileData` per pool: contact name, phone, email, gate access type, preferred arrival window, tags
- Stored in UserDefaults (JSON per pool UUID)
- Exportable/importable as part of full backup
- Foundation for future customer portal and communication features

#### 6.4 Localization (Implemented)

- In-app language override: English, Spanish (Espanol), French (Francais), Portuguese (Brasil), German (Deutsch)
- Metric/imperial unit system support via `UnitManager` (temperature, volume, dosing quantities)
- Localized strings for water conditions, chemical types, equipment types, dosing directions, notification text, PDF report content
- Accessibility labels for VoiceOver support

### Medium-Term (Natural Extensions of Current Architecture)

#### 6.5 Multi-Technician Support

- Team management: invite technicians, assign routes per tech
- Centralized dashboard for business owners across all technicians
- Per-technician performance metrics (pools serviced, chemistry accuracy, time-per-stop)
- The onboarding `businessOwner` path already targets this segment
- Would require CloudKit sharing or a lightweight backend

#### 6.6 Customer Portal / Customer-Facing Reports

- Automated email/SMS delivery of service reports after each visit
- Customer-accessible portal for viewing service history and water chemistry trends
- Leverages existing `PDFReportRenderer` infrastructure and `ShareLink` for report sharing
- Text-based report template already exists in QuickLogView (`reportText` computed property)

#### 6.7 Seasonal Contract Management

- Recurring billing schedules tied to pool service agreements
- Seasonal rate adjustments (summer premium, winter maintenance)
- Contract renewal reminders and expiration tracking
- Would extend the existing `monthlyServiceFee` on the Pool model

#### 6.8 Advanced Notification Scenarios

- Expand beyond current three scenarios (morning route summary, low stock, weekly digest)
- Equipment warranty expiration alerts (data already in `Equipment.warrantyExpiryDate`)
- Service overdue alerts (data already in `Equipment.nextServiceDate`)
- Chemistry drift alerts based on historical trend analysis
- Customer-specific reminders (preferred arrival windows)

### Long-Term (High-Impact Expansions)

#### 6.9 Parts Ordering Integration

- Partner with chemical and equipment distributors (Pentair, Hayward, Zodiac, SCP Distributors)
- In-app ordering triggered from low-stock alerts or dosing recommendations
- Auto-populate reorder quantities based on usage rates
- Equipment model already stores manufacturer and model number for parts lookup

#### 6.10 Photo AI for Water Clarity Analysis

- On-device Core ML model to analyze service photos for water clarity
- Estimate turbidity, color deviations, and algae presence from camera input
- Complement chemical readings with visual assessment
- Photo infrastructure already exists (downsampled JPEG capture in QuickLogView)

#### 6.11 Predictive Chemistry Modeling

- Use historical service event data to predict when pool chemistry will drift out of balance
- Proactive service scheduling based on LSI trend analysis
- Seasonal adjustment recommendations (summer heat drives faster chemistry drift)
- Service event history with timestamped readings already provides the training data

#### 6.12 Apple Watch Companion

- Quick-glance route status (next pool, ETA, pools remaining)
- One-tap service completion confirmation
- Haptic alerts for low-stock chemicals
- Complication for today's pool count / unserviced count

#### 6.13 Integration with Pool Equipment Manufacturers

- API integrations with Pentair ScreenLogic, Hayward OmniLogic, Zodiac iAquaLink
- Pull real-time data from connected pool equipment (flow rates, pump status, chlorinator output)
- Predictive maintenance based on equipment telemetry
- Equipment model already categorizes devices by type for natural mapping

---

## 7. Competitive Positioning

### Position Statement

PoolFlow occupies a unique position as **the only pool-specific field tool that combines real-time water chemistry (LSI with CYA correction), cost-linked dosing, and per-pool profit analytics in a single offline-first app designed for wet-hand operation.**

### Against Paper/Spreadsheet Methods

PoolFlow replaces 3-5 separate analog tools (paper route sheets, lookup tables, calculators, spreadsheets, camera app) with a single app that:
- Reduces service logging from 5-10 minutes to under 2 minutes
- Eliminates manual LSI calculation errors (CYA correction is automatic)
- Provides real-time profit visibility instead of end-of-month discovery
- Creates a searchable, exportable digital record of every service visit

### Against Generic Pool Chemistry Apps

Most pool chemistry apps provide basic calculators without:
- CYA-corrected LSI (they use simplified formulas)
- Cost-linked dosing from actual inventory prices
- Route management or scheduling
- Profit analytics or money loser detection
- Offline capability for field use

PoolFlow is not a calculator -- it is a complete field workflow.

### Against Business Management Software (Jobber, Housecall Pro, ServiceTitan)

Generic field service management platforms offer:
- Scheduling and dispatching (but not pool-chemistry-aware)
- Invoicing and payments (but not per-pool profitability from chemical costs)
- CRM (but not LSI calculations or dosing recommendations)
- Cloud-dependent operation (fails in poor connectivity)

These tools serve all home service businesses generically. PoolFlow serves pool technicians specifically, with domain expertise that generic platforms cannot match:
- LSI calculation integrated into the service logging workflow
- Dosing recommendations with costs from actual truck inventory
- 30% threshold money loser detection tied to logged chemical usage
- Equipment tracking with pool-specific categories (pump, filter, heater, salt system, etc.)

### Against the "Do Nothing" Alternative

Many solo pool techs do not use any digital tool. The onboarding flow addresses this directly:
- Two profiling questions (user type and feature focus) personalize the first experience
- "Starting fresh" path guides inline pool creation
- Feature highlights demonstrate immediate value (route, chemistry, profit)
- Post-onboarding guided tooltips teach the workflow progressively
- Free tier allows full evaluation with up to 5 pools before any purchase decision

---

## 8. Key Metrics to Track

| Metric | What It Measures | Target |
|--------|-----------------|--------|
| Daily Active Users | Core engagement | Growing week-over-week |
| Service Events Logged / Week | Core value delivery | 15-40 per active user |
| Avg. Time to Log Service | Workflow efficiency (QuickLogView) | < 2 minutes |
| Route Optimization Usage | Premium feature adoption | > 50% of multi-pool Pro users |
| Profit Dashboard Views / Week | Business analytics engagement | > 2x per active Pro user |
| Free-to-Trial Conversion | Paywall effectiveness | > 15% of users hitting pool cap |
| Trial-to-Paid Conversion | Retention and perceived value | > 40% of trial users |
| Monthly Churn Rate | Subscription health | < 8% monthly |
| Pools per User | Scale and tier fit | 20-80 (solo), 50-200+ (company) |
| Onboarding Completion Rate | First-run experience quality | > 70% complete all steps |
| Quick Log Success Count | Engagement depth | Track notification prompt eligibility (3+ logs) |
| Retention (30-day) | Product-market fit | > 60% |
| Money Losers Identified | Business impact | Track fee adjustments post-identification |
| App Review Prompt Success | Organic growth | > 50% positive when prompted |

---

## 9. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Data loss (device failure) | **High** | iCloud sync for Pro users; full ZIP backup/restore; 3-tier startup recovery (retry/reset/restore) |
| Free tier too generous (no conversion) | **Medium** | 5-pool cap creates natural upgrade moment for serious techs; analytics and route optimization locked |
| Free tier too restrictive (abandonment) | **Medium** | Full LSI calculator, service logging, and inventory available free; only scale/analytics features gated |
| Limited to iOS | **Medium** | Android market is large but iOS has higher ARPU in US service businesses; consider cross-platform later |
| Single-user limitation | **Medium** | Multi-tech support in medium-term roadmap; `businessOwner` onboarding path sets expectations |
| Competitor with cloud-native approach | **Medium** | Offline-first is a genuine differentiator for field work where connectivity is unreliable |
| App Store discovery | **High** | ASO optimization for "pool service app", "LSI calculator", "pool route planner"; industry forums; trade shows |
| RevenueCat dependency | **Low** | Graceful free-tier fallback when RevenueCat is unavailable; no hard crash on missing API key |
| Chemical constant accuracy | **Low** | Constants match industry-standard APSP lookup tables; dosing engine is thoroughly unit-tested |
| Pricing sensitivity | **Medium-High** | $29.99/mo is premium for solo techs (50% above initial $19.99 target); annual plan at $299.99/yr ($25.00/mo equivalent) provides value tier but annual commitment is significant; monitor conversion rates closely |
| StoreKit product ID naming | **Low** | Product IDs (`Pool_01`, `Pool_02`) use generic naming rather than descriptive IDs (`poolflow_pro_monthly`, `poolflow_pro_annual`); ensure App Store Connect product IDs match before release |
| Device theft (no app-level auth) | **Medium** | Customer names, addresses, gate codes stored in plaintext; add optional Face ID/passcode lock |

---

*This document describes PoolFlow's product strategy, market positioning, and growth trajectory as derived from the current codebase. For the complete feature list, see [03_Feature_Inventory](03_Feature_Inventory.md). For technical architecture, see [01_App_Blueprint](01_App_Blueprint.md). For user workflow details, see [05_Customer_Journeys](05_Customer_Journeys.md).*
