# Determination Throttling Fix

> **⚠️ NOTE:** This document describes the initial fix. A **much simpler solution** was implemented by routing IOB through the same throttled pipeline as determinations. See [GARMIN_THROTTLING_SIMPLIFIED.md](GARMIN_THROTTLING_SIMPLIFIED.md) for the final implementation.

## Problem Identified from Logs

The log file showed multiple determination updates being sent in rapid succession:
```
11:28:26 - Determination sent immediately
11:28:27 - Determination sent immediately (again)
11:28:29 - Determination sent immediately (again)
11:28:29 - Determination sent immediately (again)
```

This violated the intended 10-second throttling behavior where only the first determination should be sent, with subsequent ones within 10 seconds being discarded.

## Root Cause

The `registerHandlers()` method was calling `sendWatchStateDataImmediately()` directly instead of publishing to the `determinationSubject`. This meant the Combine throttling mechanism set up in `subscribeToDeterminationThrottle()` was being bypassed entirely.

## The Fix

### Changed: `registerHandlers()` - Line 280-318

**Before:**
```swift
// OrefDetermination - ALWAYS immediate send
coreDataPublisher?
    .filteredByEntityName("OrefDetermination")
    .sink { [weak self] _ in
        // ... setup code ...
        self.currentSendTrigger = "Determination"
        self.sendWatchStateDataImmediately(watchStateData)  // ❌ Bypasses throttling
        self.lastImmediateSendTime = Date()
        debug(.watchManager, "[\(self.formatTimeForLog())] Garmin: Determination sent immediately")
    }
```

**After:**
```swift
// OrefDetermination - publish to determinationSubject for Combine throttling
coreDataPublisher?
    .filteredByEntityName("OrefDetermination")
    .sink { [weak self] _ in
        // ... setup code ...
        self.currentSendTrigger = "Determination"
        // Publish to subject for throttling - Combine will dedupe
        self.determinationSubject.send(watchStateData)  // ✅ Uses Combine throttling
    }
```

## How It Works Now

1. **Determination change detected** → CoreData publisher fires
2. **Watch state computed** → `setupGarminSwissAlpineWatchState()` or `setupGarminTrioWatchState()`
3. **Data published** → `determinationSubject.send(watchStateData)`
4. **Combine throttles** → `subscribeToDeterminationThrottle()` with `.throttle(for: .seconds(10), latest: false)`
   - First determination: **Sent immediately**
   - Subsequent determinations within 10s: **Discarded**
5. **Broadcast** → `broadcastStateToWatchApps()` sends to watch

## Throttling Behavior

```swift
private func subscribeToDeterminationThrottle() {
    determinationSubject
        .throttle(for: .seconds(10), scheduler: DispatchQueue.main, latest: false)
        //                                                           ^^^^^^^ KEY!
        //                                                           Discards subsequent events
        .sink { [weak self] data in
            // This only fires for first determination in each 10s window
            self.lastImmediateSendTime = Date()
            self.broadcastStateToWatchApps(jsonObject)
        }
}
```

The `latest: false` parameter means:
- ✅ First event goes through immediately
- ❌ Events within next 10 seconds are **dropped**
- ✅ After 10 seconds, next event goes through

## Expected Log Output After Fix

```
11:28:26 - Garmin: Sending determination (10s throttle passed)
11:28:27 - [determination change detected but throttled/dropped]
11:28:29 - [determination change detected but throttled/dropped]
11:28:36 - Garmin: Sending determination (10s throttle passed)  // 10+ seconds later
```

## What Remains Unchanged

All other logic from this morning's session remains intact:

1. **Glucose updates** - Only immediate if loop stale > 8 minutes
2. **IOB updates** - 30-second throttling
3. **Status requests** - 30-second throttling  
4. **Settings changes** - Immediate (units/re-enable) or throttled (dataType)
5. **30s throttle cancellation** - If determination fires, pending 30s updates are cancelled

## Benefits

- ✅ **No duplicate determination sends** - Combine handles deduplication
- ✅ **Simpler code** - No manual timer management for determinations
- ✅ **Preserves all morning's work** - Glucose/IOB/Status logic untouched
- ✅ **Consistent with original design** - Uses Combine like the original codebase did
