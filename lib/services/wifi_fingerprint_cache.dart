import 'package:flutter/foundation.dart';

/// Cache for the latest Wi-Fi fingerprint from automatic community sensing.
///
/// This allows BLE detections to include the most recent Wi-Fi scan
/// for ML room prediction without blocking or performing synchronous Wi-Fi scans.
class WifiFingerprintCache {
  WifiFingerprintCache._();
  static final WifiFingerprintCache instance = WifiFingerprintCache._();

  /// Most recent Wi-Fi fingerprint: { bssid: rssi }
  Map<String, int>? _latestFingerprint;
  
  /// When the latest fingerprint was captured
  DateTime? _capturedAt;
  
  /// How long a fingerprint remains valid (2 minutes)
  static const _validityDuration = Duration(minutes: 2);

  /// Store a new Wi-Fi fingerprint.
  void update(Map<String, int> fingerprint) {
    _latestFingerprint = Map.from(fingerprint);
    _capturedAt = DateTime.now();
    debugPrint('[WiFiCache] ✓ Fingerprint cached: ${fingerprint.length} BSSIDs at ${_capturedAt!.toIso8601String()}');
  }

  /// Get the latest Wi-Fi fingerprint if still valid.
  /// Returns null if no fingerprint available or if it's too old.
  Map<String, int>? get() {
    if (_latestFingerprint == null || _capturedAt == null) {
      debugPrint('[WiFiCache] ✗ No fingerprint in cache');
      return null;
    }

    final age = DateTime.now().difference(_capturedAt!);
    if (age > _validityDuration) {
      // Fingerprint is stale
      debugPrint('[WiFiCache] ✗ Fingerprint expired (age: ${age.inSeconds}s > ${_validityDuration.inSeconds}s)');
      return null;
    }

    debugPrint('[WiFiCache] ✓ Fingerprint retrieved from cache (age: ${age.inSeconds}s, ${_latestFingerprint!.length} BSSIDs)');
    return Map.from(_latestFingerprint!);
  }

  /// Clear the cached fingerprint.
  void clear() {
    _latestFingerprint = null;
    _capturedAt = null;
  }
}
