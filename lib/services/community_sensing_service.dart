import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wifi_scan_service.dart';
import 'wifi_fingerprint_cache.dart';
import 'ble_service.dart';
import 'asset_service.dart';
import 'community_detection_service.dart';
import 'api_service.dart';

// ── Foreground task handler ────────────────────────────────────────────────

/// Runs inside the foreground-task isolate.
/// Called by flutter_foreground_task on a background timer.
///
/// NOTE: BLE scanning via flutter_blue_plus CANNOT run in this isolate
/// because it requires platform channels. The BLE scan is triggered via
/// SendPort communication to the main isolate.
@pragma('vm:entry-point')
void startCommunitySensingCallback() {
  FlutterForegroundTask.setTaskHandler(_CommunitySensingTaskHandler());
}

class _CommunitySensingTaskHandler extends TaskHandler {
  int _bleScanCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[CommunitySensing] Foreground task started.');
    await _performScans();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _performScans();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[CommunitySensing] Foreground task stopped. '
        'BLE scan requests: $_bleScanCount');
  }

  // ── Scan logic ─────────────────────────────────────────────────────────

  Future<void> _performScans() async {
    // Notify main isolate to perform BLE scan
    // The main isolate handles the actual BLE scanning because
    // flutter_blue_plus requires platform channels
    FlutterForegroundTask.sendDataToMain({
      'action': 'performBleScan',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Note: Wi-Fi scanning now runs directly in main isolate via Timer
    // No need to perform Wi-Fi scan in task isolate
  }

  @override
  void onReceiveData(Object data) {
    // Receive scan count updates from main isolate
    if (data is Map<String, dynamic>) {
      if (data['action'] == 'bleScanCompleted') {
        _bleScanCount++;
        final detections = data['detections'] as int? ?? 0;
        
        // Update notification with scan count
        FlutterForegroundTask.updateService(
          notificationText: 'Community sensing active — '
              'BLE: $_bleScanCount scans ($detections detection${detections == 1 ? '' : 's'})',
        );
      }
    }
  }
}

// ── Public service API ─────────────────────────────────────────────────────

/// Manages starting and stopping the community sensing foreground service.
///
/// This service performs BOTH:
/// 1. Wi-Fi fingerprint scanning and upload (for room prediction)
/// 2. BLE scanning for AssetGuard trackers (for community detection)
///
/// The service uses the existing [WifiScanService], [BleService], and
/// [ApiService] infrastructure.
///
/// IMPORTANT ANDROID LIMITATIONS:
/// - BLE scanning requires the main Flutter isolate (platform channels)
/// - Service survives app backgrounding but NOT process termination
/// - A persistent notification is required by Android
/// - Scan frequency may be throttled by Android power management
class CommunitySensingService {
  CommunitySensingService._();
  static final CommunitySensingService instance = CommunitySensingService._();

  /// True while the foreground service is running.
  bool get isRunning => _running;
  bool _running = false;

  /// Stream controller for receiving messages from the foreground task isolate
  StreamSubscription<dynamic>? _receivePortSub;
  
  /// Timer for periodic BLE scanning in the main isolate
  Timer? _bleScanTimer;
  
  /// Timer for periodic Wi-Fi scanning in the main isolate
  Timer? _wifiScanTimer;
  
  /// Scan counters
  int _bleScanCount = 0;
  int _wifiScanCount = 0;
  int _totalDetections = 0;

  // ── Initialisation ────────────────────────────────────────────────────

  /// Call once at app startup (e.g. in main.dart after WidgetsFlutterBinding).
  static void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId:          'assetguard_community_sensing',
        channelName:        'Community Sensing',
        channelDescription: 'AssetGuard AI background BLE & Wi-Fi scanning for community detections',
        channelImportance:  NotificationChannelImportance.LOW,
        priority:           NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification:   false,
        playSound:          false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          // Scan every 15 seconds for faster detection
          15000,
        ),
        autoRunOnBoot:              false,
        allowWakeLock:              true,
        allowWifiLock:              true,
      ),
    );
  }

  // ── Start ─────────────────────────────────────────────────────────────

  /// Request required permissions and start the foreground service.
  /// Returns a [StartResult] describing the outcome.
  Future<CommunitySensingStartResult> start() async {
    if (_running) return CommunitySensingStartResult.alreadyRunning;

    // Ensure required permissions
    final locStatus = await Permission.location.request();
    if (!locStatus.isGranted) {
      return CommunitySensingStartResult.locationPermissionDenied;
    }

    final btStatus = await Permission.bluetoothScan.request();
    if (!btStatus.isGranted && !locStatus.isGranted) {
      // On Android 11 and below, location permission allows BLE scanning
      // On Android 12+, we need bluetoothScan explicitly
      return CommunitySensingStartResult.bluetoothPermissionDenied;
    }

    // On Android 13+ also request notification permission
    await Permission.notification.request();

    // Set up receiver for messages from the foreground task isolate
    final receivePort = FlutterForegroundTask.receivePort;
    if (receivePort != null) {
      _receivePortSub = receivePort.listen(_handleDataFromTask);
    }

    final result = await FlutterForegroundTask.startService(
      serviceId:            1001,
      notificationTitle:    'AssetGuard Community Sensing',
      notificationText:     'Community sensing active — starting BLE & Wi-Fi scans…',
      notificationIcon:     null,
      callback:             startCommunitySensingCallback,
    );

    if (result is ServiceRequestSuccess) {
      _running = true;
      
      // CRITICAL FIX: Start BLE scanning directly in main isolate with a Timer
      // This ensures BLE scans happen reliably, independent of inter-isolate messaging
      _startBleScanTimer();
      
      // CRITICAL FIX: Start Wi-Fi scanning directly in main isolate with a Timer
      // This ensures Wi-Fi scans happen reliably and fingerprints are cached in the main isolate
      _startWifiScanTimer();
      
      debugPrint('[CommunitySensing] Foreground service started successfully');
      return CommunitySensingStartResult.started;
    }

    await _receivePortSub?.cancel();
    _receivePortSub = null;
    return CommunitySensingStartResult.failed;
  }

  // ── Stop ──────────────────────────────────────────────────────────────

  /// Stop the foreground service cleanly.
  Future<void> stop() async {
    if (!_running) return;
    
    // Stop BLE scan timer
    _bleScanTimer?.cancel();
    _bleScanTimer = null;
    
    // Stop Wi-Fi scan timer
    _wifiScanTimer?.cancel();
    _wifiScanTimer = null;
    
    await _receivePortSub?.cancel();
    _receivePortSub = null;
    await FlutterForegroundTask.stopService();
    _running = false;
    debugPrint('[CommunitySensing] Foreground service stopped');
  }
  
  /// Start periodic BLE scanning in the main isolate.
  /// This runs independently of the foreground task isolate to ensure reliability.
  void _startBleScanTimer() {
    // Cancel any existing timer
    _bleScanTimer?.cancel();
    
    debugPrint('[CommunitySensing] Starting BLE scan timer (15s interval)');
    
    // Perform first scan immediately
    _performBleScan();
    
    // Then schedule periodic scans every 15 seconds
    _bleScanTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      debugPrint('[CommunitySensing] Timer triggered BLE scan');
      _performBleScan();
    });
  }

  /// Start periodic Wi-Fi scanning in the main isolate.
  /// This runs independently of the foreground task isolate to ensure reliability.
  void _startWifiScanTimer() {
    // Cancel any existing timer
    _wifiScanTimer?.cancel();
    
    debugPrint('[CommunitySensing] Starting Wi-Fi scan timer (15s interval)');
    
    // Perform first scan immediately
    _performWifiScan();
    
    // Then schedule periodic scans every 15 seconds
    _wifiScanTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      debugPrint('[CommunitySensing] Timer triggered Wi-Fi scan');
      _performWifiScan();
    });
  }

  // ── BLE Community Detection ───────────────────────────────────────────

  /// Handle messages from the foreground task isolate.
  /// The task isolate cannot perform BLE scans directly (requires platform channels),
  /// so it sends a message to the main isolate to trigger a BLE scan.
  void _handleDataFromTask(dynamic data) {
    if (data is Map<String, dynamic>) {
      final action = data['action'] as String?;
      
      if (action == 'performBleScan') {
        debugPrint('[CommunitySensing] BLE scan requested by foreground task');
        _performBleScan();
      }
      // Note: Wi-Fi scanning now runs directly in main isolate via Timer
      // No need to handle 'uploadWifiScan' action from task isolate
    }
  }

  /// Perform Wi-Fi scan and upload in the main isolate.
  /// This runs in the main isolate to ensure:
  /// 1. ApiService authentication is available
  /// 2. WifiFingerprintCache is updated in the same isolate where BLE detections read it
  Future<void> _performWifiScan() async {
    try {
      debugPrint('[CommunityWiFi] Starting automatic Wi-Fi scan...');
      
      final result = await WifiScanService.instance.scanNieAccessPoints();

      if (result is WifiScanSuccess && result.accessPoints.isNotEmpty) {
        final fingerprint = result.toRssiMap();
        
        debugPrint('[CommunityWiFi] ✓ Wi-Fi scan success: ${result.accessPoints.length} NIE APs found');
        debugPrint('[CommunityWiFi] Fingerprint: ${fingerprint.length} BSSIDs');
        
        // ═══ DIAGNOSTIC: VERIFY FINGERPRINT PAYLOAD ═══
        if (fingerprint.isNotEmpty) {
          final fpRssiValues = fingerprint.values.toList();
          final fpMinRssi = fpRssiValues.reduce((a, b) => a < b ? a : b);
          final fpMaxRssi = fpRssiValues.reduce((a, b) => a > b ? a : b);
          
          debugPrint('[CommunityWiFi] ───────────────────────────────────────');
          debugPrint('[CommunityWiFi] FINGERPRINT PAYLOAD VALIDATION:');
          debugPrint('[CommunityWiFi]   Payload type: ${fingerprint.runtimeType}');
          debugPrint('[CommunityWiFi]   RSSI value type: ${fingerprint.values.first.runtimeType}');
          debugPrint('[CommunityWiFi]   Min RSSI in payload: $fpMinRssi dBm');
          debugPrint('[CommunityWiFi]   Max RSSI in payload: $fpMaxRssi dBm');
          
          // Check for invalid values in the actual payload
          final invalidEntries = fingerprint.entries.where((e) => e.value < -120 || e.value > 0).toList();
          if (invalidEntries.isNotEmpty) {
            debugPrint('[CommunityWiFi] ⚠️⚠️⚠️ CRITICAL: INVALID RSSI IN PAYLOAD ⚠️⚠️⚠️');
            debugPrint('[CommunityWiFi]   Count: ${invalidEntries.length}');
            for (final entry in invalidEntries) {
              debugPrint('[CommunityWiFi]   ⚠️ ${entry.key}: ${entry.value} dBm');
            }
          } else {
            debugPrint('[CommunityWiFi]   ✓ All RSSI values in valid range [-120, 0]');
          }
          
          // Show first 3 entries as sample
          debugPrint('[CommunityWiFi]   Sample (first 3):');
          fingerprint.entries.take(3).forEach((e) {
            debugPrint('[CommunityWiFi]     ${e.key}: ${e.value} dBm (type: ${e.value.runtimeType})');
          });
          debugPrint('[CommunityWiFi] ───────────────────────────────────────');
        }
        
        _wifiScanCount++;
        
        // Store in cache FIRST for BLE detections to use
        WifiFingerprintCache.instance.update(fingerprint);
        debugPrint('[CommunityWiFi] ✓ Fingerprint cached in main isolate');
        
        // Then upload to backend for historical tracking
        try {
          final wifiFingerprint = fingerprint.entries
              .map((e) => {'bssid': e.key, 'rssi': e.value})
              .toList();

          await ApiService.instance.post('/api/community/scan', {
            'wifiFingerprint': wifiFingerprint,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          });
          
          debugPrint('[CommunityWiFi] ✓ Upload success (scan #$_wifiScanCount)');
        } catch (uploadError) {
          debugPrint('[CommunityWiFi] ✗ Upload failed: $uploadError');
          // Continue - cache is already updated, upload failure doesn't affect room prediction
        }
      } else if (result is WifiScanFailure) {
        debugPrint('[CommunityWiFi] Wi-Fi scan failed: ${result.reason}');
      } else {
        debugPrint('[CommunityWiFi] Wi-Fi scan completed — no NIE APs nearby');
      }
    } catch (e, stackTrace) {
      debugPrint('[CommunityWiFi] Wi-Fi scan error: $e');
      debugPrint('[CommunityWiFi] Stack trace: $stackTrace');
    }
  }

  /// Perform a BLE community detection scan.
  /// This runs in the main isolate because flutter_blue_plus requires platform channels.
  Future<void> _performBleScan() async {
    debugPrint('[Community BLE] ═══ Scan started ═══');
    
    try {
      // Get all registered AssetGuard trackers to identify them during scan
      final assets = await AssetService.instance.getAssets();
      final knownTrackerIds = assets.map((a) => a.trackerId).toSet();

      debugPrint('[Community BLE] Known tracker IDs: $knownTrackerIds');
      debugPrint('[Community BLE] Starting flutter_blue_plus scan (8 seconds)...');

      // Perform BLE scan (8 seconds)
      final devices = await BleService.instance.scan(
        knownTrackerIds: knownTrackerIds,
        durationSeconds: 8,
      );

      _bleScanCount++;
      debugPrint('[Community BLE] Scan #$_bleScanCount complete: ${devices.length} total devices found');

      // Log ALL devices for diagnostics
      for (final device in devices) {
        debugPrint('[Community BLE] Device discovered:');
        debugPrint('[Community BLE]   trackerId   : ${device.trackerId}');
        debugPrint('[Community BLE]   deviceName  : ${device.deviceName}');
        debugPrint('[Community BLE]   remoteId    : ${device.remoteId}');
        debugPrint('[Community BLE]   rssi        : ${device.rssi} dBm');
      }

      // Filter for AssetGuard trackers only (AG-XXX pattern or known IDs)
      final assetGuardDevices = devices.where((device) {
        final trackerId = device.trackerId.toUpperCase();
        final isAssetGuard = trackerId.startsWith('AG-') || 
                            knownTrackerIds.contains(device.trackerId);
        
        if (isAssetGuard) {
          debugPrint('[Community BLE] ✓ AssetGuard tracker matched: ${device.trackerId}');
        } else {
          debugPrint('[Community BLE] ✗ Not AssetGuard: ${device.trackerId}');
        }
        
        return isAssetGuard;
      }).toList();

      debugPrint('[Community BLE] AssetGuard trackers detected: ${assetGuardDevices.length}');
      debugPrint('[Community BLE] Full AssetGuard device list: ${assetGuardDevices.map((d) => d.trackerId).join(', ')}');

      int detectionCount = 0;

      // Report each detected AssetGuard tracker
      for (final device in assetGuardDevices) {
        debugPrint('[Community BLE] Processing tracker: ${device.trackerId}');
        
        // Check if we should report this tracker (debouncing)
        if (!CommunityDetectionService.instance.shouldReport(device.trackerId)) {
          debugPrint('[Community BLE] ⊘ Skipping ${device.trackerId} (debounced - within 60s)');
          continue;
        }

        debugPrint('[Community BLE] → Submitting detection for ${device.trackerId}:');
        debugPrint('[Community BLE]     rssi       : ${device.rssi} dBm');
        debugPrint('[Community BLE]     remoteId   : ${device.remoteId}');
        debugPrint('[Community BLE]     detectedAt : ${device.detectedAt.toIso8601String()}');

        // Get cached Wi-Fi fingerprint for ML room prediction
        final wifiFingerprint = WifiFingerprintCache.instance.get();
        if (wifiFingerprint != null && wifiFingerprint.isNotEmpty) {
          debugPrint('[CommunityWiFi] ═══ Wi-Fi FINGERPRINT RETRIEVED FROM CACHE ═══');
          debugPrint('[CommunityWiFi]     BSSIDs: ${wifiFingerprint.length}');
          debugPrint('[CommunityWiFi]     Sample: ${wifiFingerprint.entries.take(3).map((e) => '${e.key}:${e.value}dBm').join(', ')}');
          
          // ═══ DIAGNOSTIC: VALIDATE CACHED FINGERPRINT ═══
          final cachedRssiValues = wifiFingerprint.values.toList();
          final cachedMinRssi = cachedRssiValues.reduce((a, b) => a < b ? a : b);
          final cachedMaxRssi = cachedRssiValues.reduce((a, b) => a > b ? a : b);
          
          debugPrint('[CommunityWiFi] ───────────────────────────────────────');
          debugPrint('[CommunityWiFi] CACHED FINGERPRINT VALIDATION:');
          debugPrint('[CommunityWiFi]   Value type: ${wifiFingerprint.values.first.runtimeType}');
          debugPrint('[CommunityWiFi]   Min RSSI: $cachedMinRssi dBm');
          debugPrint('[CommunityWiFi]   Max RSSI: $cachedMaxRssi dBm');
          
          final cachedInvalidEntries = wifiFingerprint.entries.where((e) => e.value < -120 || e.value > 0).toList();
          if (cachedInvalidEntries.isNotEmpty) {
            debugPrint('[CommunityWiFi] ⚠️⚠️⚠️ INVALID RSSI IN CACHED FINGERPRINT ⚠️⚠️⚠️');
            debugPrint('[CommunityWiFi]   Count: ${cachedInvalidEntries.length}');
            for (final entry in cachedInvalidEntries) {
              debugPrint('[CommunityWiFi]   ⚠️ ${entry.key}: ${entry.value} dBm');
            }
          } else {
            debugPrint('[CommunityWiFi]   ✓ All cached RSSI values valid [-120, 0]');
          }
          debugPrint('[CommunityWiFi] ───────────────────────────────────────');
        } else {
          debugPrint('[CommunityWiFi] ✗ No Wi-Fi fingerprint in cache (will report without room prediction)');
        }

        // Report to backend
        // The backend will:
        // 1. Look up the asset by trackerId (cross-user lookup)
        // 2. Verify it's LOST
        // 3. Verify it's not owned by the current user
        // 4. Create a community detection record
        // 5. If Wi-Fi fingerprint provided, call ML for room prediction
        debugPrint('[Community BLE] ═══ CALLING reportDetection() ═══');
        final success = await CommunityDetectionService.instance.reportDetection(
          trackerId: device.trackerId,
          rssi: device.rssi,
          remoteId: device.remoteId,
          detectedAt: device.detectedAt,
          wifiFingerprint: wifiFingerprint,
        );

        if (success) {
          detectionCount++;
          _totalDetections++;
          debugPrint('[Community BLE] ✓ Detection reported successfully: ${device.trackerId}');
        } else {
          debugPrint('[Community BLE] ✗ Detection rejected by backend: ${device.trackerId}');
        }
      }

      debugPrint('[Community BLE] ═══ Scan complete: $detectionCount new detections (total: $_totalDetections) ═══');

      // Update notification
      _updateNotification(detectionCount);

      // Notify the task isolate that BLE scan is complete (if connected)
      try {
        FlutterForegroundTask.sendDataToTask({
          'action': 'bleScanCompleted',
          'detections': detectionCount,
        });
      } catch (e) {
        // Ignore errors - task isolate communication is optional
        debugPrint('[Community BLE] Could not notify task isolate: $e');
      }

    } on BleException catch (e) {
      debugPrint('[Community BLE] ✗ BLE error: ${e.message}');
      _updateNotification(0);
    } catch (e, stack) {
      debugPrint('[Community BLE] ✗ Unexpected error: $e');
      debugPrint('[Community BLE] Stack trace: $stack');
      _updateNotification(0);
    }
  }
  
  /// Update the foreground service notification with current scan stats.
  void _updateNotification(int lastDetectionCount) {
    try {
      FlutterForegroundTask.updateService(
        notificationText: 'Community sensing active — '
            'BLE: $_bleScanCount, Wi-Fi: $_wifiScanCount, $_totalDetections detections',
      );
    } catch (e) {
      debugPrint('[Community BLE] Could not update notification: $e');
    }
  }
}

/// Outcome of a [CommunitySensingService.start] call.
enum CommunitySensingStartResult {
  started,
  alreadyRunning,
  locationPermissionDenied,
  bluetoothPermissionDenied,
  failed,
}
