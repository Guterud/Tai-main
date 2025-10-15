# Garmin Debug Logging Control

## Overview

GarminManager now has two debug flags to control logging verbosity:

```swift
/// Enable/disable debug logging for watch state (SwissAlpine/Trio data being sent)
private let debugWatchState = true

/// Enable/disable general Garmin debug logging (connections, settings, throttling, etc.)
private let debugGarmin = true
```

## Debug Flags

### `debugWatchState`
Controls logging of watch data being prepared and sent:
- SwissAlpine: "📱 SwissAlpine: Sending 24 entries..."
- Trio: "📱 Trio: Sending to watchface..."
- State setup: "⌚️ Current basal rate...", "⌚️ SwissAlpine: TBR mode..."

**Set to `false` to disable watch data logging.**

### `debugGarmin`
Controls general Garmin operational logging:
- Throttling: "30s timer fired", "Not caching - data may be from before watchface change"
- Connections: "connected", "notConnected", "App not installed"
- Settings: "Watchface changed", "Cache cleared", "Re-registered devices"
- Registration: "Skipping watchface registration", "Registering data field"
- Messages: "Received message status", "Status request queued"

**Set to `false` to disable verbose Garmin logging.**

## Always-On Logs

These critical logs **ALWAYS show** regardless of debug flags:

### 1. Send Status (Always On)
```
[13:45:15] Garmin: Sending watch-state to app EC3420F6-027D-49B3-B45F-D81D6D3ED90A
[13:45:15] Garmin: Sending watch-state to app 71CF0982-CA41-42A5-8441-EA81D36056C3
```

### 2. Send Success/Failure (Always On)
```
[13:45:15] Garmin: Successfully sent message to EC3420F6-027D-49B3-B45F-D81D6D3ED90A [Trigger: Settings-Units/Re-enable]
[13:45:16] Garmin: Successfully sent message to 71CF0982-CA41-42A5-8441-EA81D36056C3 [Trigger: Settings-Units/Re-enable]
[13:45:20] Garmin: FAILED to send to 71CF0982-... [Trigger: Determination] (Failure #1)
```

**Why always on:** These logs show the actual communication status with the watch, which is critical for debugging connectivity issues.

## Usage Examples

### Scenario 1: Production (Minimal Logging)
```swift
private let debugWatchState = false
private let debugGarmin = false
```
**Output:** Only send status and success/failure messages

### Scenario 2: Watch Data Debugging
```swift
private let debugWatchState = true
private let debugGarmin = false
```
**Output:** Watch data + send status messages

### Scenario 3: Connection Debugging
```swift
private let debugWatchState = false
private let debugGarmin = true
```
**Output:** Connection status, throttling, settings + send status messages

### Scenario 4: Full Debugging (Default)
```swift
private let debugWatchState = true
private let debugGarmin = true
```
**Output:** Everything

## Implementation

### Helper Method
```swift
/// Helper method for conditional Garmin debug logging
private func debugGarmin(_ message: String) {
    guard debugGarmin else { return }
    debug(.watchManager, message)
}
```

### Usage
```swift
// Conditional logging
debugGarmin("[\\(formatTimeForLog())] Garmin: 30s timer fired")

// Always-on logging
debug(.watchManager, "[\\(formatTimeForLog())] Garmin: Successfully sent message to \\(app.uuid!)")
```

## Log Categories

### Watch State Logs (`debugWatchState`)
```
📱 SwissAlpine: Sending 24 entries to datafield 71CF0982-... only (watchface disabled)
📱 Trio: Sending to watchface EC3420F6-... / datafield 71CF0982-...
⌚️ Current basal rate: 0.9 U/hr from temp basal
⌚️ SwissAlpine: TBR mode selected, excluding eventualBG from JSON
⌚️⛔ Skipping setupGarminTrioWatchState - No Garmin devices connected
```

### Garmin Operation Logs (`debugGarmin`)
```
[13:45:15] Garmin: Sending determination/IOB (20s throttle passed)
[13:45:15] Garmin: Not caching - data may be from before watchface change (5s ago)
[13:45:15] Garmin: 30s timer fired - sending collected updates
[13:45:15] Garmin: 30s throttle timer started
[13:45:15] Garmin: connected (2172438F-E991-A5E1-D1D2-D7D5DCCD7C02)
[13:45:15] Garmin: Skipping watchface registration - data disabled
[13:45:15] Garmin: Watchface changed from Trio to SwissAlpine
[13:45:15] Garmin: Cleared cached determination data due to watchface change
[13:45:15] Garmin: Received message status from app 71CF0982-...
[13:45:15] Garmin: Status request queued for throttled send
[13:45:15] Garmin: Using cached determination data for immediate settings update
```

### Always-On Logs (Critical)
```
[13:45:15] Garmin: Sending watch-state to app EC3420F6-027D-49B3-B45F-D81D6D3ED90A
[13:45:15] Garmin: Successfully sent message to EC3420F6-... [Trigger: Determination]
[13:45:15] Garmin: FAILED to send to 71CF0982-... [Trigger: IOB-Update] (Failure #2)
```

## Benefits

✅ **Reduced log noise in production** - Turn off verbose logging
✅ **Targeted debugging** - Enable only what you need
✅ **Always see critical info** - Send status never hidden
✅ **Easy to toggle** - Single boolean per category
✅ **Zero performance impact** - Guard clauses skip logging entirely

## Recommendations

- **Development:** Both flags `true`
- **Beta testing:** `debugWatchState = false`, `debugGarmin = true`
- **Production:** Both flags `false`
- **Troubleshooting connectivity:** `debugGarmin = true`
- **Troubleshooting data format:** `debugWatchState = true`

## Summary

Two simple flags control all Garmin logging, while critical send status messages always show. Perfect balance of verbosity and clarity! 🎯
