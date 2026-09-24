import '../models/detection_model.dart';
import 'api_service.dart';

/// Submits a hybrid detection payload to POST /api/detections.
///
/// Combines the BLE hit (trackerId + RSSI), GPS reading, and
/// Wi-Fi fingerprint into a single payload and calls the backend.
class DetectionService {
  DetectionService._();
  static final DetectionService instance = DetectionService._();

  /// Submit a detection event.
  ///
  /// [trackerId]        — the tracker ID matched from BLE advertisement
  /// [bleRssi]          — raw dBm from the BLE scan result
  /// [gps]              — GPS fix (may be null if unavailable)
  /// [wifiFingerprint]  — list of visible APs (may be empty)
  ///
  /// Returns a [DetectionResult] with the backend-resolved position.
  /// Throws [ApiException] on HTTP errors.
  Future<DetectionResult> submitDetection({
    required String trackerId,
    required int bleRssi,
    GpsReading? gps,
    List<WifiAp> wifiFingerprint = const [],
  }) async {
    final payload = DetectionPayload(
      trackerId:       trackerId,
      bleRssi:         bleRssi,
      gps:             gps,
      wifiFingerprint: wifiFingerprint,
      timestamp:       DateTime.now(),
    );

    final data = await ApiService.instance.post(
      '/api/detections',
      payload.toJson(),
    );

    return DetectionResult.fromJson(data as Map<String, dynamic>);
  }
}
