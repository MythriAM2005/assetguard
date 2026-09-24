# Community Sensing Timing Analysis

## Current Configuration

### Scan Interval
- **Foreground Task repeat interval:** 75,000 ms (75 seconds)
- **Main isolate Timer.periodic:** 75 seconds
- **BLE scan duration:** 8 seconds per scan
- **Actual cycle time:** ~75 seconds between scan starts

**Location:** 
- `lib/services/community_sensing_service.dart` line 163: `75000` (foreground task)
- `lib/services/community_sensing_service.dart` line 254: `Duration(seconds: 75)` (timer)

### Debounce Interval
- **Per-tracker cooldown:** 60 seconds
- **Implementation:** In-memory `Map<String, DateTime>`
- **Scope:** Per tracker ID (AG-001, AG-002, etc. tracked separately)

**Location:**
- `lib/utils/community_detection_config.dart` line 7: `debounceIntervalSeconds = 60`

### BLE Scan Duration
- **Active scan time:** 8 seconds
- **Idle time between scans:** ~67 seconds (75 - 8)

**Location:**
- `lib/services/community_sensing_service.dart` line 292: `durationSeconds: 8`

---

## Why the Observed Delay is Occurring

### Timeline of a Typical Detection Cycle

```
T=0s    : Scan #1 starts (8s duration)
T=8s    : Scan #1 completes, AG-001 detected → HTTP POST → MongoDB insert
T=8s    : _lastReported['AG-001'] = now() [debounce starts]
T=75s   : Scan #2 starts (8s duration)
T=83s   : Scan #2 completes, AG-001 detected again
T=83s   : shouldReport('AG-001')? elapsed=75s >= 60s → YES → HTTP POST → MongoDB insert
T=83s   : _lastReported['AG-001'] = now() [debounce resets]
T=150s  : Scan #3 starts...
```

**Key insights:**
1. First detection happens immediately when Community Sensing starts
2. Second detection happens 75 seconds later (after debounce expires at 60s)
3. Subsequent detections happen every 75 seconds
4. The 75-second scan interval is the bottleneck, not the 60-second debounce

**Why 75 seconds?**
- Original design choice: "balance between responsiveness and battery"
- Wi-Fi scanning (NIE APs) is also performed every 75 seconds
- Foreground service overhead considerations

---

## Proposed Optimization

### New Values

**Scan interval:** 15 seconds (down from 75 seconds)
- **Rationale:** 5× more frequent detection while remaining battery-friendly
- **Battery impact:** Minimal — BLE scanning is relatively low-power on modern Android
- **Network impact:** Controlled by debounce — HTTP requests limited by 30s cooldown

**Debounce interval:** 30 seconds (down from 60 seconds)
- **Rationale:** Allows 2 detections per minute maximum per tracker
- **Protection:** Still prevents flooding (no more than 120 requests/hour per tracker)
- **Balance:** Faster updates for lost assets without overwhelming backend

**BLE scan duration:** 8 seconds (unchanged)
- **Rationale:** Proven to reliably detect AG-001 and other BLE devices
- **Coverage:** 8-second active scan + 7-second idle = 15-second cycle

### Expected Behavior After Change

```
T=0s    : Scan #1 starts (8s duration)
T=8s    : AG-001 detected → MongoDB insert [detection #1]
T=15s   : Scan #2 starts (8s duration)
T=23s   : AG-001 detected → debounced (elapsed=15s < 30s) → skipped
T=30s   : Scan #3 starts (8s duration)
T=38s   : AG-001 detected → MongoDB insert [detection #2] (elapsed=30s >= 30s)
T=45s   : Scan #4 starts...
T=53s   : AG-001 detected → debounced (elapsed=15s < 30s) → skipped
T=60s   : Scan #5 starts...
T=68s   : AG-001 detected → MongoDB insert [detection #3] (elapsed=30s >= 30s)
```

**MongoDB records per tracker per hour:**
- **Maximum theoretical:** 120 (every 30 seconds)
- **Actual expected:** ~120 (if tracker continuously present)
- **Current system:** ~48 (every 75 seconds)
- **Increase:** 2.5× more detections

---

## Risk Assessment

### LOW RISK ✓
- **Background sensing:** Unchanged — still automatic, no button required
- **Debounce protection:** Still active — prevents duplicate records within 30s
- **Security/ownership:** Unchanged — backend still validates LOST status and owner
- **Manual scan:** Unchanged — owner "Scan for Devices" unaffected
- **MongoDB schema:** Unchanged — same document structure

### MODERATE CONSIDERATIONS ⚠️
- **Battery drain:** 5× more BLE scans = slightly higher battery usage (likely <5% impact)
- **Backend load:** 2.5× more HTTP requests (still well within capacity for community sensing)
- **Network data:** 2.5× more API calls (negligible — ~500 bytes per detection)

### MITIGATION
- User can stop Community Sensing anytime if battery drain is noticed
- Backend already handles rate limiting via JWT auth and debounce
- Scan frequency can be adjusted further if needed (e.g., 20s instead of 15s)

---

## Files to Modify

### 1. `lib/utils/community_detection_config.dart`
```dart
// BEFORE
static const int debounceIntervalSeconds = 60;

// AFTER
static const int debounceIntervalSeconds = 30;
```

### 2. `lib/services/community_sensing_service.dart` (2 locations)
```dart
// BEFORE (line ~163)
ForegroundTaskEventAction.repeat(
  // Scan every 75 seconds (balance between responsiveness and battery)
  75000,
)

// AFTER
ForegroundTaskEventAction.repeat(
  // Scan every 15 seconds for faster detection
  15000,
)
```

```dart
// BEFORE (line ~254)
_bleScanTimer = Timer.periodic(const Duration(seconds: 75), (_) {

// AFTER
_bleScanTimer = Timer.periodic(const Duration(seconds: 15), (_) {
```

**Total changes:** 3 numeric constants in 2 files

---

## Implementation Safety Checks

✅ No changes to BLE scanning logic  
✅ No changes to HTTP request construction  
✅ No changes to backend validation  
✅ No changes to MongoDB schema  
✅ No changes to owner detection flow  
✅ No changes to JWT authentication  
✅ Debounce still prevents duplicates  
✅ Background service still automatic  

---

## Expected Outcomes

### User Experience
- **User B:** Detects AG-001 every ~30 seconds (instead of every 75 seconds)
- **User A (owner):** Receives notifications more frequently (2× faster updates)
- **Battery:** Slight increase (<5%), acceptable for community sensing use case

### MongoDB Growth Rate
- **Before:** ~48 records/hour per tracker (if continuously present)
- **After:** ~120 records/hour per tracker (if continuously present)
- **Storage impact:** Negligible (CommunityDetection documents are ~200 bytes each)

### Detection Latency
- **Worst case (missed scan):** 15 seconds (down from 75 seconds)
- **Best case (immediate detection):** 0-8 seconds (unchanged)
- **Average:** ~7.5 seconds (down from ~37.5 seconds)

---

## Rollback Plan

If battery drain becomes unacceptable:

**Option A:** Increase scan interval to 30 seconds (middle ground)
```dart
// 30-second scans, 30-second debounce
eventAction: ForegroundTaskEventAction.repeat(30000)
Timer.periodic(const Duration(seconds: 30), ...)
```

**Option B:** Revert to original 75-second scans, keep 30-second debounce
```dart
// Original scan rate, faster debounce
eventAction: ForegroundTaskEventAction.repeat(75000)
Timer.periodic(const Duration(seconds: 75), ...)
debounceIntervalSeconds = 30; // still allows 2 detections per 2.5min cycle
```

**Option C:** Full revert to original values
```dart
75000 / Duration(seconds: 75) / debounceIntervalSeconds = 60
```

---

## Test Validation Criteria

✅ User B's notification updates from "19 scans" to "100+ scans" within ~30 minutes  
✅ MongoDB shows 2+ new documents for AG-001 within 60 seconds  
✅ Each document has unique `detectedAt` timestamps ~30 seconds apart  
✅ No duplicate documents within the same 30-second window  
✅ Backend logs show requests arriving every ~30 seconds (not every 15s — debounce working)  
✅ User B's battery drain remains <5% per hour  
✅ Manual "Scan for Devices" still works for User A  

---

## Alternative Configurations (if 15s is too aggressive)

| Scan Interval | Debounce | Records/Hour | Latency (avg) | Battery Impact |
|---------------|----------|--------------|---------------|----------------|
| **15s** (proposed) | 30s | ~120 | ~7.5s | Low |
| 20s | 30s | ~90 | ~10s | Very Low |
| 30s | 30s | ~60 | ~15s | Minimal |
| 45s | 30s | ~60 | ~22.5s | Minimal |
| 75s (current) | 60s | ~48 | ~37.5s | Negligible |

**Recommendation:** Start with 15s/30s. If battery feedback is negative, adjust to 20s/30s or 30s/30s.
