# Cache Timing Fix for Watchface Changes

## The Problem

When switching watchfaces, stale format data from the throttle pipeline was being cached, causing crashes or corrupted displays.

### Root Cause

Combine's `.throttle()` creates a **20-second window**. Data published before a watchface change can come through the throttle AFTER the watchface change, getting cached with the wrong format.

**Example:**
```
13:25:29 - SwissAlpine determination published → goes into throttle
13:25:29 - Sent immediately, cached (SwissAlpine format) ✅

13:25:40 - User switches to Trio watchface
13:25:40 - Cache cleared ✅

13:25:49 - OLD SwissAlpine data (from 13:25:29) exits throttle window
13:25:49 - Gets cached again! ❌ Wrong format for Trio!

13:26:02 - User re-enables watchface
13:26:02 - Uses cached SwissAlpine data
13:26:02 - Sends to Trio watchface → CRASH or corrupted display ❌
```

### Why This Happens

1. Throttle window is **20 seconds**
2. Watchface change can happen mid-throttle
3. Old format data "in flight" in the throttle gets cached after the watchface changes
4. Next immediate send uses wrong format

## The Solution

**Track when the watchface was last changed and don't cache data that might be from before the change.**

### Implementation

#### 1. Add Timestamp Property
```swift
/// Track when watchface was last changed to prevent caching stale format data
private var lastWatchfaceChangeTime: Date?
```

#### 2. Set Timestamp on Watchface Change
```swift
if watchfaceChanged {
    cachedDeterminationData = nil
    lastWatchfaceChangeTime = Date()  // ← NEW
}
```

#### 3. Conditional Caching in Throttle Subscriber
```swift
.sink { [weak self] data in
    guard let self = self else { return }
    
    // Only cache if no recent watchface change (>25s ago)
    let shouldCache: Bool
    if let lastChange = self.lastWatchfaceChangeTime {
        let timeSinceChange = Date().timeIntervalSince(lastChange)
        shouldCache = timeSinceChange > 25 // Throttle is 20s + 5s buffer
        
        if !shouldCache {
            debug("Not caching - data may be from before watchface change")
        }
    } else {
        shouldCache = true // No recent watchface change
    }
    
    if shouldCache {
        self.cachedDeterminationData = data  // ✅ Safe!
    }
    
    // Still send to watch (for completion of current cycle)
    self.broadcastStateToWatchApps(jsonObject)
}
```

## How It Works

```
Timeline with fix:

13:25:29 - SwissAlpine determination published
13:25:29 - Sent through throttle, cached ✅

13:25:40 - Watchface changed to Trio
13:25:40 - Cache cleared ✅
13:25:40 - lastWatchfaceChangeTime = 13:25:40 ✅

13:25:49 - Old SwissAlpine data exits throttle
13:25:49 - Check: Time since change = 9s (< 25s)
13:25:49 - DON'T cache (skip it) ✅
13:25:49 - Send to watch anyway (complete the cycle)
13:25:49 - Log: "Not caching - data may be from before watchface change"

[Wait for next determination...]

13:26:10 - New Trio determination published
13:26:30 - New Trio data exits throttle (20s later)
13:26:30 - Check: Time since change = 50s (> 25s)
13:26:30 - Cache it! ✅ Correct Trio format!

13:27:00 - User re-enables watchface
13:27:00 - Uses cached data
13:27:00 - Sends Trio format to Trio watchface ✅ Success!
```

## Why 25 Seconds?

- Throttle window: **20 seconds**
- Buffer time: **5 seconds** (for clock skew, processing delays)
- Total safe window: **25 seconds**

Any data that exits the throttle within 25 seconds of a watchface change is **potentially stale format** and should not be cached.

## Edge Cases Handled

### Multiple Rapid Watchface Changes
```
13:25:00 - SwissAlpine data published
13:25:10 - Switch to Trio (lastChangeTime = 13:25:10)
13:25:15 - Switch to SwissAlpine (lastChangeTime = 13:25:15)
13:25:20 - Old data exits throttle
13:25:20 - Time since change = 5s (< 25s) → Don't cache ✅
```

### Watchface Change After Cache Populated
```
13:25:00 - Trio data cached
13:25:30 - Switch to SwissAlpine
13:25:30 - Cache cleared immediately ✅
```

### First Run (No Previous Change)
```
App starts - lastWatchfaceChangeTime = nil
First determination - shouldCache = true ✅
```

## Log Messages

**When skipping cache due to recent change:**
```
[13:25:49] Garmin: Not caching - data may be from before watchface change (9s ago)
```

**When watchface changes:**
```
Garmin: Cleared cached determination data due to watchface change
```

**When using cache:**
```
Garmin: Using cached determination data for immediate settings update
```

## Testing Checklist

- [ ] Switch watchface → Wait 30s → Change settings → No stale data
- [ ] Switch watchface → Immediate settings change → Falls back to CoreData (acceptable)
- [ ] Switch watchface rapidly (multiple times) → No crashes
- [ ] Normal operation without watchface changes → Cache works normally
- [ ] Check logs for "Not caching" messages after watchface changes

## Files Changed

- **GarminManager.swift**
  - Added `lastWatchfaceChangeTime` property
  - Set timestamp on watchface change
  - Conditional caching in throttle subscriber

## Summary

By tracking when the watchface was last changed and skipping cache updates for data that might be from before the change, we **eliminate format mismatch bugs** while maintaining cache freshness for normal operations.

**The 25-second safety window ensures stale format data never enters the cache!** 🎯
