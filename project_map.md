# PoolFlow — Project Architecture Map

## 1. Project Identity

| Attribute | Value |
|-----------|-------|
| **App Name** | PoolFlow |
| **Platform** | iOS (SwiftUI-first, no UIKit views) |
| **Language** | Swift 5.9+ |
| **Min Deployment** | iOS 17+ (inferred from SwiftData + @Observable) |
| **Entry Point** | `PoolFlow/App/PoolFlowApp.swift` → `@main struct PoolFlowApp` |
| **Lines of Code** | ~2,920 across 14 source files |

## 2. Primary Frameworks

| Framework | Usage |
|-----------|-------|
| **SwiftUI** | All views, navigation, state management |
| **SwiftData** | Persistence layer (models, queries, relationships) |
| **MapKit** | Apple Maps directions launch (`PoolListView`) |
| **CoreLocation** | Address geocoding (`AddPoolView`) |
| **PhotosUI** | Proof-of-service photo picker (`QuickLogView`) |
| **UIKit** | Conditional — haptic feedback only (`Theme.swift`) |

**Dependency Management:** None. Zero external dependencies. All frameworks are Apple first-party.

## 3. Architecture Pattern: MVVM

```
┌─────────────────────────────────────────────────────────────┐
│                        @main App                            │
│  PoolFlowApp.swift                                          │
│  ├── ModelContainer (SwiftData schema)                      │
│  └── ContentView (TabView root)                             │
│       ├── Tab 1: PoolListView (Route)                       │
│       └── Tab 2: DosingCalculatorView (Dose)                │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│    Views     │────▶│  ViewModels  │────▶│     Engine       │
│  (SwiftUI)   │     │ (@Observable)│     │ (Pure Functions) │
└──────────────┘     └──────────────┘     └──────────────────┘
       │                    │                      │
       ▼                    ▼                      ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│   SwiftData  │◀───▶│   Models     │◀────│  Calculations    │
│  (@Query)    │     │   (@Model)   │     │  (LSI, Dosing)   │
└──────────────┘     └──────────────┘     └──────────────────┘
```

### Layer Responsibilities

| Layer | Files | Role |
|-------|-------|------|
| **App** | `PoolFlowApp.swift`, `Theme.swift` | Entry point, SwiftData container, design system |
| **Views** | 5 files | UI rendering, user interaction, sheet/navigation management |
| **ViewModels** | `PoolListViewModel.swift`, `DosingViewModel.swift` | Observable state, business logic binding |
| **Engine** | `LSICalculator.swift`, `DosingEngine.swift` | Pure calculation functions, no UI/persistence coupling |
| **Models** | `Pool.swift`, `ServiceEvent.swift`, `ChemicalInventory.swift` | SwiftData `@Model` classes with relationships |

## 4. Module Dependency Graph

```
PoolFlowApp
├── ContentView
│   ├── PoolListView
│   │   ├── PoolListViewModel
│   │   ├── Pool (@Query)
│   │   ├── LSICalculator
│   │   ├── Theme
│   │   ├── QuickLogView ──────────────────────┐
│   │   │   ├── Pool (passed in)               │
│   │   │   ├── ChemicalInventory (@Query)     │
│   │   │   ├── LSICalculator                  │
│   │   │   ├── DosingEngine                   │
│   │   │   └── Theme                          │
│   │   ├── AddPoolView                        │
│   │   │   ├── Pool (created)                 │
│   │   │   ├── CLGeocoder (async)             │
│   │   │   └── Theme                          │
│   │   └── PoolDetailView                     │
│   │       ├── Pool (@Bindable)               │
│   │       ├── DosingViewModel                │
│   │       ├── LSICalculator                  │
│   │       ├── DosingEngine                   │
│   │       ├── Theme                          │
│   │       ├── QuickLogView (sheet) ──────────┘
│   │       ├── DosingCalculatorView (sheet)
│   │       │   ├── DosingViewModel
│   │       │   ├── ChemicalInventory (@Query)
│   │       │   ├── LSICalculator (via VM)
│   │       │   ├── DosingEngine (via VM)
│   │       │   └── Theme
│   │       └── EditPoolView (sheet)
│   │           ├── Pool (@Bindable)
│   │           └── Theme
│   └── DosingCalculatorView (standalone, no pool)
│       └── (same deps as above, pool = nil)
└── Seed: ChemicalInventory.defaultCatalog()
```

## 5. Persistence Layer

| Component | Technology | Notes |
|-----------|-----------|-------|
| **ORM** | SwiftData | Type-safe, offline-first |
| **Storage** | SQLite (via SwiftData) | `isStoredInMemoryOnly: false` |
| **Photo Storage** | `@Attribute(.externalStorage)` | JPEG data stored outside main DB |
| **Schema** | 4 models | Pool, ServiceEvent, ChemicalDose, ChemicalInventory |
| **Migrations** | Automatic (SwiftData default) | No explicit migration plan |

### Data Relationships

```
Pool (1) ──cascade──▶ (N) ServiceEvent
ServiceEvent (1) ──cascade──▶ (N) ChemicalDose
ChemicalInventory (1) ──nullify──▶ (N) ChemicalDose
```

## 6. Networking Stack

**None.** This is a fully offline-first application. The only network-touching code is:
- `CLGeocoder.geocodeAddressString()` in `AddPoolView.savePool()` — background, fire-and-forget, error silently ignored.

## 7. Navigation Architecture

```
TabView (root)
├── Tab 1: NavigationStack
│   └── PoolListView
│       └── NavigationLink → PoolDetailView
│           ├── .sheet → QuickLogView (half-sheet: .medium/.large)
│           ├── .sheet → DosingCalculatorView (full sheet)
│           └── .sheet → EditPoolView (full sheet)
├── Tab 2: NavigationStack
│   └── DosingCalculatorView (standalone, pool = nil)
└── .sheet → AddPoolView (from PoolListView toolbar)
```

## 8. Design System

Centralized in `Theme.swift` (enum namespace):
- **Touch targets**: 44pt minimum, 56pt buttons
- **Corner radii**: 12/14/16pt hierarchy
- **Colors**: Role-based (LSI status, chemical type, slider tint)
- **Haptics**: Pre-warmed generators (notification, light impact, medium impact)
- **Chemistry ranges**: Status evaluation (Low/Ideal/High)

## 9. Key Observations

| Observation | Status |
|-------------|--------|
| External dependencies | **Zero** — all Apple-native |
| Test coverage | **None** — no test files exist |
| Xcode project file | **Missing** — no .xcodeproj or Package.swift |
| Info.plist | **Missing** — no explicit plist found |
| Accessibility | **No explicit support** — no accessibilityLabel/Value modifiers |
| Localization | **None** — all strings hardcoded in English |
| Error handling | **Minimal** — silent failures for geocoding and photo loading |
| Concurrency model | **Mixed** — Task{} + DispatchQueue.main.asyncAfter |
