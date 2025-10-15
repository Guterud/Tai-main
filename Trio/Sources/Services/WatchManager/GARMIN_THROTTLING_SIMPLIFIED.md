# Garmin Update Throttling - Simplified Solution

## Problem Identified from Logs

### Issue 1: Multiple Determination Sends
```
11:28:26 - Determination sent immediately
11:28:27 - Determination sent immediately (again)  ❌ Duplicate
11:28:29 - Determination sent immediately (again)  ❌ Duplicate
```

### Issue 2: IOB and Determination Fire Simultaneously
```
11:43:34 - Sending determination (10s throttle passed)
11:43:34 - 30s throttle timer started  ❌ IOB starting unnecessary timer
11:44:04 - 30s timer fired  ❌ Duplicate send with same data
```

**Root cause:** IOB and Determination are computed in the same loop cycle, so they fire at exactly the same time. This caused race conditions and duplicate sends.

## The Elegant Solution

**Instead of complex race condition handling, just route IOB through the same throttled pipeline as determinations!**

Since they fire simultaneously anyway, treating them as one update stream eliminates all race conditions.

## Changes Made

### 1. Determination Handler - Use Combine Throttling
**File:** `registerHandlers()` - Line ~280-318

**Before:**
```swift
self.currentSendTrigger = "Determination"
self.sendWatchStateDataImmediately(watchStateData)  // ❌ Bypasses throttling
```

**After:**
```swift
self.currentSendTrigger = "Determination"
self.determinationSubject.send(watchStateData)  // ✅ Uses Combine throttling
```

### 2. IOB Handler - Use Same Pipeline as Determinations
**File:** `init()` - Line ~208-243

**Before:**
```swift
iobService.iobPublisher
    .sink { [weak self] _ in
        // ...
        self.currentSendTrigger = "IOB-Update"
        self.sendWatchStateDataWith30sThrottle(watchStateData)  // ❌ Separate 30s pipeline
    }
```

**After:**
```swift
iobService.iobPublisher
    .sink { [weak self] _ in
        // ...
        self.currentSendTrigger = "IOB-Update"
        self.determinationSubject.send(watchStateData)  // ✅ Same throttled pipeline
    }
```

### 3. Update Throttle Handler
**File:** `subscribeToDeterminationThrottle()` - Line ~896-913

**Updated to handle both:**
```swift
private func subscribeToDeterminationThrottle() {
    determinationSubject
        .throttle(for: .seconds(10), scheduler: DispatchQueue.main, latest: false)
        .sink { [weak self] data in
            // Handle BOTH determination and IOB updates
            debug("Sending determination/IOB (10s throttle passed)")
            self.lastImmediateSendTime = Date()
            self.broadcastStateToWatchApps(jsonObject)
        }
}
```

## How It Works Now

```
Loop Cycle Completes
    ├─> Determination fires ─┐
    │                        ├─> determinationSubject
    └─> IOB fires ───────────┘
                             │
                             ↓
                    Combine .throttle(10s)
                      (latest: false)
                             │
                             ↓
                    First event: SENT ✅
                    Next 9.9s: DROPPED ❌
                             │
                             ↓
                    After 10s: Next event SENT ✅
```

## Update Routing Summary

| Update Type | Old Behavior | New Behavior |
|------------|--------------|--------------|
| **Determination** | Immediate send (no throttle) ❌ | 10s Combine throttle ✅ |
| **IOB** | 30s manual timer ❌ | 10s Combine throttle ✅ |
| **Glucose (stale loop)** | Immediate send ✅ | Unchanged ✅ |
| **Status requests** | 30s manual timer ✅ | Unchanged ✅ |
| **Settings changes** | Immediate or 30s ✅ | Unchanged ✅ |

## Expected Log Output After Fix

### Scenario: Normal loop cycle (determination + IOB fire together)

**Before:**
```
11:43:34 - Determination sent immediately
11:43:34 - 30s throttle timer started (IOB)
11:43:35 - Determination sent immediately  ← Duplicate!
11:44:04 - 30s timer fired  ← Duplicate with same data!
```

**After:**
```
11:43:34 - Sending determination/IOB (10s throttle passed)
[Both determination and IOB updates dropped for next 10s]
11:43:44 - Sending determination/IOB (10s throttle passed)
[Clean, single send every 10s]
```

### Scenario: Status request during loop cycle

**Before:**
```
11:43:34 - Determination sent
11:43:34 - 30s throttle timer started (IOB)
11:43:42 - Status request ignored (just sent 8s ago)
11:44:04 - 30s timer fired  ← Unnecessary send
```

**After:**
```
11:43:34 - Sending determination/IOB (10s throttle passed)
11:43:42 - Status request ignored (just sent 8s ago)
[30s timer never starts - no unnecessary send]
```

## Benefits of This Approach

✅ **Eliminates race conditions** - Both use same pipeline, no timing issues
✅ **Simpler code** - Removed complex race condition checks
✅ **Fewer timer objects** - No more 30s timer for IOB
✅ **Less code to maintain** - ~50 lines of race condition handling removed
✅ **More predictable** - Single throttle point, single behavior
✅ **Same effective update rate** - Every loop cycle still sends once (via throttle)
✅ **Preserves all other logic** - Glucose/Status/Settings unchanged

## Why This Works Better

**Old approach:** Two separate throttle mechanisms (immediate + 30s timer)
- Complex coordination required
- Race conditions between publishers
- Multiple timer objects to manage
- Unpredictable interaction between timers

**New approach:** Single throttle mechanism (10s Combine)
- Both updates go through same funnel
- Combine handles all deduplication
- One timer managed by Combine
- Predictable, deterministic behavior

## Technical Notes

### Why 10 seconds?
- Typical loop cycle: 5 minutes
- Multiple events within 10s are from same loop cycle
- After 10s, next loop cycle has completed → send new data
- Reduces watch transmissions while staying responsive

### Why `latest: false`?
- `latest: false` = Keep **first** event, drop rest
- This ensures we send data immediately when loop completes
- Alternative `latest: true` would wait 10s, then send last event (laggy)

### What about standalone IOB updates?
- IOB can change without determination (e.g., time-based decay)
- These still go through same 10s throttle
- If IOB changes alone, it will send after throttle period
- This is acceptable since IOB-only changes are minor

## Removed Complexity

### Before (Complex Race Handling)
```swift
// Set flag FIRST to prevent race
self.lastImmediateSendTime = Date()

// Cancel any running 30s timer
if self.throttleTimer30s?.isValid == true {
    self.throttleTimer30s?.invalidate()
    self.throttleTimer30s = nil
    // ... cleanup ...
}

// Check if determination just fired
if let lastImmediate = lastImmediateSendTime,
   Date().timeIntervalSince(lastImmediate) < 5 {
    return  // Skip this update
}
```

### After (Simple Throttling)
```swift
// Just publish to shared subject - Combine handles everything
self.determinationSubject.send(watchStateData)
```

**Result:** ~50 lines of complex race condition handling → 1 line

## Migration Notes

If you had IOB-specific monitoring or logging that checked for "IOB-Update" triggers, those will now go through the determination throttle. The `currentSendTrigger` still tracks whether the original source was IOB or Determination for debugging purposes.
