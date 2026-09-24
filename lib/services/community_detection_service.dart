import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/community_detection_config.dart';
import 'api_service.dart';
import 'location_service.dart';

/// Manages community detection reporting with debouncing.
///
/// When a user detects a LOST AssetGuard tracker, this service reports
/// the detection to the backend. Duplicate reports for the same tracker
/// are debounced to prevent flooding.
class CommunityDetectionService {
  CommunityDetectionService._();
  static final CommunityDetectionService instance =
      CommunityDetectionService._();

  /// In-memory debounce map: trackerId → last reported timestamp
  final Map<String, DateTime> _lastReported = {};

  /// Check if enough time has passed since the last report for this tracker.
  bool shouldReport(String trackerId) {
    final lastTime = _lastReported[trackerId];
    if (lastTime == null) {
      debugPrint('[CommunityDetection] shouldReport($trackerId): YES (never reported)');
      return true;
    }

    final elapsed = DateTime.now().difference(lastTime).inSeconds;
    final shouldReport = elapsed >= CommunityDetectionConfig.debounceIntervalSeconds;
    
    if (shouldReport) {
      debugPrint('[CommunityDetection] shouldReport($trackerId): YES (elapsed: ${elapsed}s >= ${CommunityDetectionConfig.debounceIntervalSeconds}s)');
    } else {
      debugPrint('[CommunityDetection] shouldReport($trackerId): NO (elapsed: ${elapsed}s < ${CommunityDetectionConfig.debounceIntervalSeconds}s, last: $lastTime)');
    }
    
    return shouldReport;
  }

  /// Report a community detection to the backend.
  ///
  /// The backend will verify that the asset is actually LOST before accepting.
  ///
  /// Optionally includes Wi-Fi fingerprint for ML room prediction.
  ///
  /// Returns true if the report was successful, false otherwise.
  Future<bool> reportDetection({
    required String trackerId,
    required int rssi,
    String? remoteId,
    required DateTime detectedAt,
    Map<String, int>? wifiFingerprint,
  }) async {
    try {
      // Get current location (best effort - don't block if unavailable)
      double? latitude;
      double? longitude;
      
      try {
        final position = await LocationService.instance.getPosition();
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
        }
      } catch (e) {
        debugPrint('[Community] Could not get location: $e');
        // Continue without location
      }

      final payload = {
        'trackerId': trackerId,
        'rssi': rssi,
        if (remoteId != null) 'remoteId': remoteId,
        'detectedAt': detectedAt.toUtc().toIso8601String(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (wifiFingerprint != null && wifiFingerprint.isNotEmpty) 
          'wifiFingerprint': wifiFingerprint,
      };

      debugPrint('[Community] ═══════════════════════════════════════');
      debugPrint('[Community] ► SUBMITTING DETECTION TO BACKEND');
      debugPrint('[Community]   trackerId  : $trackerId');
      debugPrint('[Community]   rssi       : $rssi dBm');
      debugPrint('[Community]   remoteId   : $remoteId');
      debugPrint('[Community]   detectedAt : ${detectedAt.toUtc().toIso8601String()}');
      if (latitude != null && longitude != null) {
        debugPrint('[Community]   location   : $latitude, $longitude');
      }
      if (wifiFingerprint != null && wifiFingerprint.isNotEmpty) {
        debugPrint('[CommunityWiFi] ✓ Wi-Fi fingerprint INCLUDED in payload');
        debugPrint('[CommunityWiFi]   BSSIDs: ${wifiFingerprint.length}');
        debugPrint('[CommunityWiFi]   Sample: ${wifiFingerprint.entries.take(3).map((e) => '${e.key}:${e.value}dBm').join(', ')}');
      } else {
        debugPrint('[CommunityWiFi] ✗ NO Wi-Fi fingerprint in payload');
      }
      debugPrint('[Community] ═══════════════════════════════════════');

      final response = await ApiService.instance.post(
        '/api/community/detections',
        payload,
      );

      // Update debounce timestamp on success
      _lastReported[trackerId] = DateTime.now();

      debugPrint('[Community] ═══════════════════════════════════════');
      debugPrint('[Community] ◄ BACKEND RESPONSE RECEIVED');
      debugPrint('[Community]   status     : SUCCESS (201/200)');
      debugPrint('[Community]   message    : ${response['message']}');
      
      // Log ML room prediction if available
      if (response['predictedRoom'] != null) {
        debugPrint('[CommunityWiFi] ═══ ML ROOM PREDICTION RECEIVED ═══');
        debugPrint('[CommunityWiFi] ✓ Predicted room: ${response['predictedRoom']}');
        debugPrint('[CommunityWiFi] ✓ Confidence: ${response['confidence']}');
        debugPrint('[CommunityWiFi] ═══════════════════════════════════════');
      } else {
        debugPrint('[CommunityWiFi] ℹ No room prediction in response');
      }
      debugPrint('[Community] ═══════════════════════════════════════');

      return true;
    } on ApiException catch (e) {
      debugPrint('[Community] ◄ Response status: ${e.statusCode}');
      debugPrint('[Community]   error      : ${e.message}');
      
      // 404 means asset not found or not LOST — this is expected behavior
      if (e.statusCode == 404) {
        debugPrint('[Community] ℹ Tracker $trackerId not LOST or not found — this is normal');
        return false;
      }

      // 403 might mean owner trying to report own asset
      if (e.statusCode == 403) {
        debugPrint('[Community] ℹ Tracker $trackerId rejected — might be owned by current user');
        return false;
      }

      debugPrint('[Community] ✗ Report failed for $trackerId: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Community] ✗ Unexpected error reporting $trackerId: $e');
      return false;
    }
  }

  /// Clear the debounce map (useful for testing or manual reset).
  void clearDebounceMap() {
    _lastReported.clear();
    debugPrint('[CommunityDetection] Debounce map cleared');
  }
}
