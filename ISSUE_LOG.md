# PoolFlow — Technical Issue Log

> Generated from deep-dive audit against `project_map.md`.
> Issues ranked: **Critical** (Crashes/Data Loss) → **High** (Performance/UX) → **Medium** (Tech Debt).

---

## Critical — Crashes / Data Loss

### CRIT-1: Force Unwraps in `LSICalculator.interpolate()` Can Crash on Malformed Tables

**File:** `Engine/LSICalculator.swift:153-171`
**Category:** Memory Safety

```swift
if value <= table.first!.0 {     // line 153 — force unwrap
    return table.first!.1         // line 154 — force unwrap
}
if value >= table.last!.0 {      // line 157 — force unwrap
    return table.last!.1          // line 158 — force unwrap
}
// ...
return table.last!.1              // line 171 — force unwrap
```

The `guard !table.isEmpty` on line 150 only protects against a fully empty array. The 5 force-unwraps (`!`) are technically safe for the current hardcoded tables, but `interpolate` is a `static` method with a public `table` parameter — any future caller passing an empty table after the guard check's early return (safe), or any refactoring that changes the guard, will cause a crash. The function signature invites misuse.

**Risk:** Runtime crash (`fatalError` via forced optional unwrap) if called with unexpected input during future refactoring.
**Fix:** Replace `table.first!` / `table.last!` with safe guard-let bindings.

---

### CRIT-2: `PoolFlowApp.sharedModelContainer` Uses `fatalError` on Schema Failure

**File:** `App/PoolFlowApp.swift:24`
**Category:** Error Handling

```swift
} catch {
    fatalError("Could not create ModelContainer: \(error)")
}
```

If SwiftData schema migration fails (e.g., after a model property rename or type change without a migration plan), the app crashes immediately on launch with no recovery path. On a real device this creates a "bricked" state — the user's only option is to delete and reinstall the app, losing all data.

**Risk:** Unrecoverable crash after model schema changes. Total data loss on reinstall.
**Fix:** Show an error alert with a "Reset Data" option, or implement a SwiftData migration plan. At minimum, log the error and present a recovery UI.

---

### CRIT-3: `AddPoolView.savePool()` Mutates SwiftData Model After View Dismissal

**File:** `Views/AddPoolView.swift:97-117`
**Category:** Modern Concurrency / Data Safety

```swift
dismiss()                    // line 97 — view is dismissed

Task {                       // line 104 — async geocoding continues
    // ...
    await MainActor.run {
        pool.latitude = ...  // line 109 — mutates pool after view is gone
        pool.longitude = ... // line 110
    }
}
```

After `dismiss()`, the SwiftUI view hierarchy is torn down. The `Task` closure captures `pool` (a SwiftData `@Model` reference) and mutates it on `MainActor` after the view's `modelContext` may have been deallocated or changed. SwiftData models are tied to their originating `ModelContext`. While the `pool` object was inserted into the context _before_ dismiss and the container's `mainContext` persists, this pattern is fragile — if the dismiss triggers context cleanup or the pool is deleted before geocoding returns, this will crash or silently corrupt state.

**Risk:** Potential crash or silent data corruption if the pool is deleted between dismiss and geocoding completion.
**Fix:** Capture the `modelContext` explicitly and perform geocoding update through the persistent container's `mainContext` rather than relying on the dismissed view's environment.

---

## High — Performance / UX

### HIGH-1: Repeated O(N) Sorting of `serviceEvents` on Every Computed Access

**Files:** Multiple locations
**Category:** Performance

The pattern `pool.serviceEvents.sorted(by: { $0.timestamp > $1.timestamp }).first` appears in:
- `DosingViewModel.loadFromPool()` (line 53)
- `QuickLogView.prefill()` (line 292)
- `PoolDetailView.recentEvents` (line 263)
- `PoolListView.lastServiceDate()` (line 50)

Each call sorts the entire `serviceEvents` array just to get the most recent event. For a pool with hundreds of service visits over years of use, this is O(N log N) per access. In `PoolListView`, this is called once per visible pool row, and `PoolDetailView` calls it in the scroll body.

**Risk:** UI jank on pools with large service histories. Each re-render re-sorts.
**Fix:** Use `.max(by:)` instead of `.sorted(...).first` — this is O(N) instead of O(N log N) and avoids allocating a temporary sorted array.

---

### HIGH-2: `DispatchQueue.main.asyncAfter` for Timed Dismissals Instead of Structured Concurrency

**Files:** `PoolListView.swift:125`, `QuickLogView.swift:336`, `DosingCalculatorView.swift:241`
**Category:** Modern Concurrency

Three views use `DispatchQueue.main.asyncAfter(deadline:)` for auto-dismissing overlays/toasts:

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    withAnimation { showRouteComplete = false }
}
```

This is a legacy GCD pattern. If the view is deallocated before the delay fires, the closure still executes and mutates `@State` on a destroyed view. SwiftUI is resilient to this (it silently ignores the mutation), but it's technically undefined behavior and violates structured concurrency principles.

**Risk:** Potential for stale state mutation after view teardown. Mild — SwiftUI absorbs it, but it's a code smell.
**Fix:** Replace with `Task { try? await Task.sleep(for: .seconds(2)); ... }` which gets automatically cancelled when the view's task scope ends, or use SwiftUI's `.task` modifier with sleep.

---

### HIGH-3: No Accessibility Support (VoiceOver, Dynamic Type Limits)

**Files:** All Views
**Category:** Interface Resilience

No `accessibilityLabel`, `accessibilityValue`, or `accessibilityHint` modifiers are applied anywhere in the codebase. Key issues:

1. **LSI value** (`DosingCalculatorView:64`): VoiceOver reads "+0.24" as individual characters, not "LSI is plus zero point two four, balanced."
2. **Chemistry tiles** (`PoolDetailView:139`): No semantic grouping — VoiceOver reads "p H", "seven point four", "Ideal" as three separate elements.
3. **Stepper buttons** (`QuickLogView:147-184`): VoiceOver reads "minus.circle.fill" (the SF Symbol name) instead of "Decrease pH."
4. **Route progress** (`PoolListView:183`): Progress bar has no accessibility representation.
5. **Photo thumbnail** (`QuickLogView:219`): No alt text for captured image.

**Risk:** App is unusable for VoiceOver users. Apple may reject App Store submission for accessibility violations.
**Fix:** Add `accessibilityLabel` and `accessibilityValue` to all interactive elements and data displays. Group related elements with `accessibilityElement(children: .combine)`.

---

### HIGH-4: No Dynamic Type / Content Size Category Resilience

**Files:** All Views
**Category:** Interface Resilience

Several layout constraints break with large accessibility text sizes:

1. **Day picker circles** (`PoolListView:154-169`): Fixed `frame(width: 48, height: 48)` clips text at large Dynamic Type sizes.
2. **Route order badge** (`PoolListView:296-310`): Fixed `frame(width: 36, height: 36)` — single-digit numbers overflow at larger sizes.
3. **Priority circles** (`DosingCalculatorView:337`): Fixed `frame(width: 32, height: 32)` — same issue.
4. **Touch target frames** (`QuickLogView:163-164`): Fixed `frame(width: 44, height: 44)` may be too small for accessibility sizes.

**Risk:** UI breaks for users with accessibility text size settings. Content truncation and overlap.
**Fix:** Use `.frame(minWidth:minHeight:)` instead of fixed frames, or use `@ScaledMetric` for dimension values.

---

### HIGH-5: Photo Data Loaded Into Memory Without Size Limits

**File:** `Views/QuickLogView.swift:212`
**Category:** Memory Safety

```swift
if let data = try? await newItem?.loadTransferable(type: Data.self) {
    photoData = data
}
```

A full-resolution photo from a modern iPhone can be 5-15 MB. This raw `Data` is:
1. Stored in `@State` (kept in memory for the view's lifetime)
2. Rendered as `Image(uiImage: UIImage(data: photoData))` (decoded again into a bitmap — 30-50 MB for a 12MP image)
3. Persisted to SwiftData with `@Attribute(.externalStorage)` — which is fine, but the in-memory pressure during the view is significant

**Risk:** Memory pressure on older devices. No crash, but background apps may be terminated.
**Fix:** Downsample the photo on load using `UIImage` with `CGImageSourceCreateThumbnailAtMaxPixelSize` before storing, or use `UIImage(data:)?.preparingThumbnail(of:)`.

---

### HIGH-6: `LSIResult` Constructed with Dummy Factors in `serviceEventRow`

**File:** `Views/PoolDetailView.swift:300-304`
**Category:** Protocol Implementation / Code Smell

```swift
let lsiStatus = LSICalculator.LSIResult(
    lsiValue: event.lsiValue,
    temperatureFactor: 0, calciumFactor: 0, alkalinityFactor: 0,
    pH: event.pH, tdsFactor: 0
).status
```

An `LSIResult` is constructed with 4 zeroed-out factors purely to access the `.status` computed property (which only uses `lsiValue`). This violates the struct's invariants — a result with `temperatureFactor: 0, calciumFactor: 0, ...` is physically meaningless.

**Risk:** No runtime issue, but misleading semantics. Future code inspecting factors on this result will get wrong data.
**Fix:** Extract `WaterCondition.from(lsiValue:)` as a standalone static method, or add a convenience init/static factory that only requires `lsiValue`.

---

## Medium — Tech Debt

### MED-1: No SwiftData Migration Strategy

**File:** `App/PoolFlowApp.swift:9-26`
**Category:** Architecture

The `ModelContainer` uses automatic schema discovery with no explicit `VersionedSchema` or `SchemaMigrationPlan`. If any `@Model` property is renamed, retyped, or removed in a future version, the app will crash on launch (see CRIT-2).

**Risk:** Any model change = crash for existing users. No way to evolve the schema safely.
**Fix:** Define a `VersionedSchema` and `SchemaMigrationPlan` for the current schema as V1, even if no migration is needed yet. This establishes the baseline for safe future evolution.

---

### MED-2: `WaterCondition` Enum Is Not `Codable` or `Hashable`

**File:** `Engine/LSICalculator.swift:44`
**Category:** Protocol Implementation

```swift
enum WaterCondition: String, Equatable {
```

`WaterCondition` conforms to `Equatable` but not `Hashable` or `Codable`. Since it's a `String`-backed enum, adding `: Hashable, Codable` is free and enables use as dictionary keys, in `Set`s, and in persistence if needed.

**Risk:** Limits future usability. No immediate issue.
**Fix:** Add `Hashable, Codable` conformances.

---

### MED-3: `DosingRecommendation` Creates New UUID on Every Recomputation

**File:** `Engine/DosingEngine.swift:13`
**Category:** Performance / SwiftUI Identity

```swift
struct DosingRecommendation: Identifiable {
    let id = UUID()
```

`recommendations` is a computed property on `DosingViewModel`. Every time SwiftUI re-evaluates the body, new `DosingRecommendation` instances are created with new `UUID`s. This means SwiftUI's diffing sees them as _entirely new_ elements, causing the `ForEach` to destroy and recreate all recommendation card views on every slider change — breaking animations and wasting CPU.

**Risk:** Unnecessary view churn on every input change. Prevents smooth cell animations.
**Fix:** Derive a stable identity from the recommendation's content (e.g., `chemicalType.rawValue + priority`) instead of a random UUID.

---

### MED-4: Inconsistent Concurrency Pattern — `Task` vs `DispatchQueue`

**Files:** `AddPoolView.swift:104`, `QuickLogView.swift:211`, `PoolListView.swift:125`, `DosingCalculatorView.swift:241`
**Category:** Modern Concurrency

The codebase mixes two concurrency patterns:
- `Task { await ... }` for async work (geocoding, photo loading)
- `DispatchQueue.main.asyncAfter` for delayed UI work (overlay dismissal)

**Risk:** Inconsistent mental model. `Task` integrates with structured concurrency (cancellation, priority); `DispatchQueue` does not.
**Fix:** Standardize on `Task` + `Task.sleep` for all delayed work.

---

### MED-5: `DosingEngine.recommend()` Has Fragile Threshold Coupling

**File:** `Engine/DosingEngine.swift:108-222`
**Category:** Architecture

The dosing thresholds (pH 7.4/7.6, TA 80/120, CH 200/400) are hardcoded inline. The same thresholds are hardcoded separately in `Theme.swift` for range indicators (`pHStatus`, `alkalinityStatus`, etc.). If one is updated without the other, the UI and engine disagree on what's "ideal."

**Risk:** Drift between engine thresholds and UI indicators.
**Fix:** Centralize ideal ranges in a shared constants struct that both `DosingEngine` and `Theme` reference.

---

### MED-6: Silent Error Swallowing in Two Locations

**Files:** `App/PoolFlowApp.swift:43`, `Views/QuickLogView.swift:212`
**Category:** Error Handling

1. `(try? context.fetchCount(descriptor)) ?? 0` — If SwiftData fails to count inventory, the app silently re-seeds defaults, potentially duplicating the catalog.
2. `try? await newItem?.loadTransferable(type: Data.self)` — Photo loading failure is invisible to the user. They tap "Add Photo", nothing happens, no error shown.

**Risk:** Subtle data corruption (duplicate inventory) or confusing UX (silent photo failure).
**Fix:** For (1), use `do/catch` with logging. For (2), show a brief error state on the photo button.

---

### MED-7: No SwiftUI Previews

**Files:** All View files
**Category:** Interface Resilience

None of the 7 view files contain `#Preview` macros or `PreviewProvider` implementations. This makes iterating on UI changes significantly slower — every change requires a full build and run cycle.

**Risk:** Slower development velocity. No visual regression checking.
**Fix:** Add `#Preview` blocks with mock data for all views.

---

### MED-8: `Pool` Model Lacks `Identifiable` Conformance Declaration

**File:** `Models/Pool.swift:8`
**Category:** Protocol Implementation

```swift
@Model
final class Pool {
    var id: UUID
```

`Pool` has an `id: UUID` property but doesn't explicitly conform to `Identifiable`. SwiftData's `@Model` macro synthesizes `Identifiable` conformance via `PersistentModel`, so this works at runtime. However, the implicit conformance makes it unclear to readers and IDE tooling whether `Pool` is intentionally `Identifiable`.

**Risk:** Reader confusion. No runtime issue.
**Fix:** No change needed — this is informational. SwiftData handles it.

---

## Summary

| Severity | Count | Key Themes |
|----------|-------|------------|
| **Critical** | 3 | Force unwraps, fatalError on schema failure, post-dismiss mutation |
| **High** | 6 | O(N log N) sorts, no accessibility, memory-unsafe photo loading, dummy struct construction |
| **Medium** | 8 | No migration plan, inconsistent concurrency, threshold drift, no previews |
| **Total** | 17 | |
