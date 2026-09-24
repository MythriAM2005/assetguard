import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';

/// Represents a single Wi-Fi access point result for NIE localization.
class NieAccessPoint {
  /// Network name (SSID) — e.g. "NIE-STUDENTS"
  final String ssid;

  /// Normalized BSSID in lowercase colon-separated MAC format.
  /// e.g. "84:d8:1b:aa:bb:cc"
  final String bssid;

  /// Raw signal strength in dBm — e.g. -43
  /// Never converted to percentage, bars, or any other scale.
  final int rssiDbm;

  /// UTC time when this reading was taken.
  final DateTime timestamp;

  const NieAccessPoint({
    required this.ssid,
    required this.bssid,
    required this.rssiDbm,
    required this.timestamp,
  });

  /// Returns this AP as a BSSID → RSSI entry for the ML model.
  MapEntry<String, int> toMapEntry() => MapEntry(bssid, rssiDbm);

  @override
  String toString() => 'NieAccessPoint(ssid: $ssid, bssid: $bssid, rssi: $rssiDbm dBm)';
}

/// Result of a Wi-Fi localization scan.
sealed class WifiScanResult {}

/// Scan succeeded — may contain zero or more NIE access points.
final class WifiScanSuccess extends WifiScanResult {
  final List<NieAccessPoint> accessPoints;
  WifiScanSuccess(this.accessPoints);

  /// ML-ready format: { bssid: rssiDbm }
  Map<String, int> toRssiMap() =>
      Map.fromEntries(accessPoints.map((ap) => ap.toMapEntry()));
}

/// Scan could not be performed — includes a human-readable reason.
final class WifiScanFailure extends WifiScanResult {
  final String reason;
  WifiScanFailure(this.reason);
}

/// Scans for NIE campus Wi-Fi access points and returns raw RSSI values.
///
/// Only networks with SSID "NIE-STUDENTS" or "NIE-STAFF" are included.
/// All other networks are silently discarded.
///
/// BSSID strings are normalized to lowercase colon-separated MAC format.
/// RSSI is returned as raw dBm — no conversion to percentage or bars.
class WifiScanService {
  WifiScanService._();
  static final WifiScanService instance = WifiScanService._();

  /// SSIDs we care about for room localization.
  static const _targetSsids = {'NIE-STUDENTS', 'NIE-STAFF'};

  // ── Public API ──────────────────────────────────────────────────────────

  /// Perform a Wi-Fi scan and return NIE access points with raw RSSI.
  ///
  /// Returns [WifiScanSuccess] with (possibly empty) list of APs,
  /// or [WifiScanFailure] with a reason string.
  Future<WifiScanResult> scanNieAccessPoints() async {
    // 1. Ensure location permission is granted (required by wifi_scan on Android)
    final locStatus = await Permission.location.status;
    if (!locStatus.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        return WifiScanFailure(
          'Location permission is required for Wi-Fi scanning on Android. '
          'Please grant it in Settings → App Permissions.',
        );
      }
    }

    // 2. Check whether a scan can be started
    final canStart = await WiFiScan.instance.canStartScan(askPermissions: false);
    switch (canStart) {
      case CanStartScan.yes:
        break;
      case CanStartScan.notSupported:
        return WifiScanFailure('Wi-Fi scanning is not supported on this device.');
      case CanStartScan.noLocationPermissionRequired:
      case CanStartScan.noLocationPermissionDenied:
      case CanStartScan.noLocationPermissionUpgradeAccuracy:
        return WifiScanFailure(
          'Location permission is required for Wi-Fi scanning. '
          'Please grant it in Settings.',
        );
      case CanStartScan.noLocationServiceDisabled:
        return WifiScanFailure(
          'Location services are disabled. '
          'Please enable Location in your device settings.',
        );
      case CanStartScan.failed:
        return WifiScanFailure('Wi-Fi scan could not be started. Please try again.');
    }

    // 3. Start the scan
    final started = await WiFiScan.instance.startScan();
    if (!started) {
      // Android may return false when a cached result is already fresh — continue anyway
    }

    // 4. Check whether results can be read
    final canGet = await WiFiScan.instance.canGetScannedResults(askPermissions: false);
    if (canGet != CanGetScannedResults.yes) {
      return WifiScanFailure(
        'Wi-Fi scan results are unavailable. '
        '${_canGetMessage(canGet)}',
      );
    }

    // 5. Retrieve raw results
    final List<WiFiAccessPoint> raw;
    try {
      raw = await WiFiScan.instance.getScannedResults();
    } catch (e) {
      return WifiScanFailure('Failed to read scan results: $e');
    }

    if (raw.isEmpty) {
      return WifiScanSuccess([]);
    }

    // 6. Filter to NIE networks and normalize
    final now = DateTime.now().toUtc();
    
    // ═══ TEMPORARY DIAGNOSTIC LOGGING ═══
    // Capture RSSI values BEFORE any processing
    debugPrint('[WiFiScan] ═══════════════════════════════════════');
    debugPrint('[WiFiScan] RAW SCAN RESULTS ANALYSIS');
    debugPrint('[WiFiScan] Total APs found: ${raw.length}');
    
    final nieRawAps = raw.where((ap) => _targetSsids.contains(ap.ssid.trim())).toList();
    debugPrint('[WiFiScan] NIE APs found: ${nieRawAps.length}');
    
    if (nieRawAps.isNotEmpty) {
      // Analyze RSSI values from raw scan
      final rssiValues = nieRawAps.map((ap) => ap.level).toList();
      final minRssi = rssiValues.reduce((a, b) => a < b ? a : b);
      final maxRssi = rssiValues.reduce((a, b) => a > b ? a : b);
      
      debugPrint('[WiFiScan] ───────────────────────────────────────');
      debugPrint('[WiFiScan] RSSI ANALYSIS:');
      debugPrint('[WiFiScan]   Type: ${nieRawAps.first.level.runtimeType}');
      debugPrint('[WiFiScan]   Min RSSI: $minRssi dBm');
      debugPrint('[WiFiScan]   Max RSSI: $maxRssi dBm');
      
      // Check for out-of-range values
      final outOfRange = nieRawAps.where((ap) => ap.level < -120 || ap.level > 0).toList();
      debugPrint('[WiFiScan]   Out of range [-120,0]: ${outOfRange.length}');
      
      if (outOfRange.isNotEmpty) {
        debugPrint('[WiFiScan] ⚠️ WARNING: OUT-OF-RANGE RSSI VALUES DETECTED:');
        for (final ap in outOfRange) {
          debugPrint('[WiFiScan]   ⚠️ BSSID: ${ap.bssid}, RSSI: ${ap.level} dBm, SSID: ${ap.ssid}');
        }
      }
      
      // Sample first 3 for verification
      debugPrint('[WiFiScan] ───────────────────────────────────────');
      debugPrint('[WiFiScan] SAMPLE DATA (first 3 NIE APs):');
      for (var i = 0; i < nieRawAps.length && i < 3; i++) {
        final ap = nieRawAps[i];
        debugPrint('[WiFiScan]   BSSID: ${ap.bssid}, RSSI: ${ap.level} dBm (type: ${ap.level.runtimeType}), SSID: ${ap.ssid}');
      }
    }
    debugPrint('[WiFiScan] ═══════════════════════════════════════');
    
    final accessPoints = raw
        .where((ap) => _targetSsids.contains(ap.ssid.trim()))
        .map((ap) => NieAccessPoint(
              ssid:    ap.ssid.trim(),
              bssid:   _normalizeBssid(ap.bssid),
              rssiDbm: ap.level, // raw dBm — no conversion
              timestamp: now,
            ))
        .toList();

    // Sort by signal strength (strongest first) for readability
    accessPoints.sort((a, b) => b.rssiDbm.compareTo(a.rssiDbm));
    
    // ═══ POST-PROCESSING VERIFICATION ═══
    if (accessPoints.isNotEmpty) {
      final postMinRssi = accessPoints.map((ap) => ap.rssiDbm).reduce((a, b) => a < b ? a : b);
      final postMaxRssi = accessPoints.map((ap) => ap.rssiDbm).reduce((a, b) => a > b ? a : b);
      
      debugPrint('[WiFiScan] POST-PROCESSING VERIFICATION:');
      debugPrint('[WiFiScan]   Min RSSI after mapping: $postMinRssi dBm');
      debugPrint('[WiFiScan]   Max RSSI after mapping: $postMaxRssi dBm');
      
      final postOutOfRange = accessPoints.where((ap) => ap.rssiDbm < -120 || ap.rssiDbm > 0).toList();
      if (postOutOfRange.isNotEmpty) {
        debugPrint('[WiFiScan] ⚠️ OUT-OF-RANGE AFTER PROCESSING: ${postOutOfRange.length}');
        for (final ap in postOutOfRange) {
          debugPrint('[WiFiScan]   ⚠️ ${ap.bssid}: ${ap.rssiDbm} dBm');
        }
      }
    }

    return WifiScanSuccess(accessPoints);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Normalize BSSID to lowercase colon-separated MAC format.
  /// Handles: "84:D8:1B:AA:BB:CC" → "84:d8:1b:aa:bb:cc"
  ///          "84-D8-1B-AA-BB-CC" → "84:d8:1b:aa:bb:cc"
  String _normalizeBssid(String raw) {
    return raw
        .trim()
        .replaceAll('-', ':')
        .toLowerCase();
  }

  String _canGetMessage(CanGetScannedResults reason) {
    switch (reason) {
      case CanGetScannedResults.noLocationPermissionRequired:
      case CanGetScannedResults.noLocationPermissionDenied:
      case CanGetScannedResults.noLocationPermissionUpgradeAccuracy:
        return 'Location permission is required.';
      case CanGetScannedResults.noLocationServiceDisabled:
        return 'Location services are disabled.';
      case CanGetScannedResults.notSupported:
        return 'Not supported on this device.';
      default:
        return 'Please try again.';
    }
  }
}
