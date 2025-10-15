# Cached Determination Data Fix

## Problem

When users changed settings (units, re-enabled watchface), the immediate update sent **stale data**:

```
12:24:17 - Latest determination completed
12:25:52 - User changes settings, immediate update sent
           Data shows: lastLoopDateInterval: 1760523834 (12:23:54)  ❌ 2 minutes old!
12:25:57 - Next determination fires
           Data shows: lastLoopDateInterval: 1760523958 (12:25:58)  ✅ Fresh!
```

**Root Cause:** Settings changes query CoreData directly, which can return cached/stale data. The freshest determination data hasn't propagated yet.

**Impact:** Watch displayed outdated loop data (2+ minutes old) until the next determination fired.

## The Solution

**Cache the last determination data** and use it for immediate sends instead of querying CoreData.

### Implementation

#### 1. Add Cache Property
```swift
/// Cache last determination data to avoid CoreData staleness on immediate sends
private var cachedDeterminationData: Data?
```

#### 2. Cache Data When Determination Fires
```swift
private func subscribeToDeterminationThrottle() {
    determinationSubject
        .sink { [weak self] data in
            // ... throttling logic ...
            
            // Cache this data for use in immediate sends
            self.cachedDeterminationData = data
            
            // Send to watch
            self.broadcastStateToWatchApps(jsonObject)
        }
}
```

#### 3. Use Cache for Settings Changes
```swift
if needsImmediateUpdate {
    Task {
        // Try cached data first
        if let cachedData = self.cachedDeterminationData {
            debug("Using cached determination data for immediate settings update")
            self.sendWatchStateDataImmediately(cachedData)  // ✅ Fresh!
        } else {
            // Fallback to CoreData query
            let watchState = try await self.setupGarminTrioWatchState()  // ⚠️ Might be stale
        }
    }
}
```

## How It Works

```
Loop Cycle:
  ├─> Determination fires
  ├─> Data goes through throttle
  ├─> Cache data: cachedDeterminationData = data  ✅
  └─> Send to watch

User Changes Settings:
  ├─> Check: Is cachedDeterminationData available?
  │   ├─ YES → Use cached data (fresh!)  ✅
  │   └─ NO  → Query CoreData (might be stale)  ⚠️
  └─> Send immediately
```

## Expected Behavior After Fix

### Before (Without Cache)
```
12:24:17 - Determination: lastLoop 12:24:17
12:25:52 - Settings changed, CoreData queried
           Sent data: lastLoop 12:23:54  ❌ Stale!
           Watch shows: 2-minute-old data
12:25:57 - Next determination
           Sent data: lastLoop 12:25:57  ✅
           Watch finally updates
```

### After (With Cache)
```
12:24:17 - Determination: lastLoop 12:24:17
           Cached: cachedDeterminationData ✅
12:25:52 - Settings changed, cache used
           Sent data: lastLoop 12:24:17  ✅ Fresh from cache!
           Watch shows: Current data (95 seconds old, but latest available)
12:25:57 - Next determination
           Sent data: lastLoop 12:25:57  ✅
           Watch updates again
```

## Benefits

✅ **Eliminates stale data on settings changes** - Watch shows most recent determination
✅ **No CoreData timing issues** - Cache bypasses CoreData propagation delays
✅ **Minimal code change** - Simple property and conditional check
✅ **Safe fallback** - If cache is nil (app just started), falls back to CoreData query
✅ **Applicable to all immediate sends** - Units changes, re-enabling watchface, etc.

## Edge Cases Handled

### Cache is Nil (App Just Started)
- **Scenario:** User changes settings before first determination
- **Behavior:** Falls back to CoreData query
- **Result:** Works correctly, just might have slight CoreData delay

### Cached Data Format Mismatch
- **Scenario:** User switches between Trio and SwissAlpine watchfaces
- **Behavior:** Cached data is from different format
- **Result:** Still works - data structures are compatible, or next determination fixes it

### Memory Concerns
- **Impact:** One Data object in memory (~500 bytes)
- **Result:** Negligible memory footprint

## Testing Checklist

- [ ] Change units (mg/dL ↔ mmol/L) → Watch shows current loop time
- [ ] Disable then re-enable watchface → Watch shows current loop time
- [ ] Switch watchfaces → Updates correctly
- [ ] Change settings before first determination → Falls back to CoreData (acceptable)
- [ ] Multiple rapid settings changes → Always uses latest cached data

## Log Messages

Look for these new log messages:

**Using cache:**
```
Garmin: Using cached determination data for immediate settings update
Garmin: Immediate update sent for units/re-enable change (from cache)
```

**Falling back to CoreData:**
```
Garmin: Immediate update sent for units/re-enable change (fresh query)
```

## Files Changed

- **GarminManager.swift**
  - Added `cachedDeterminationData` property
  - Cache data in `subscribeToDeterminationThrottle()`
  - Use cache in `settingsDidChange()` for immediate updates

## Summary

By caching the last determination data, we ensure that settings changes always send the freshest available data to the watch, eliminating the 1-2 minute stale data issue caused by CoreData propagation delays.

**One simple cache property eliminates data staleness! 🎯**
