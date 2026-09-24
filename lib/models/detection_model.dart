/// Represents a resolved position from the backend.
class DetectionPosition {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String method; // 'GPS' | 'WIFI' | 'HYBRID' | 'BLE_ONLY'

  const DetectionPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.method,
  });

  factory DetectionPosition.fromJson(Map<String, dynamic> json) {
    return DetectionPosition(
      latitude:  (json['latitude']  as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy:  (json['accuracy']  as num?)?.toDouble(),
      method:    json['method'] as String? ?? 'BLE_ONLY',
    );
  }

  /// Human-readable summary for display in the UI.
  String get summary {
    if (latitude != null && longitude != null) {
      final lat = latitude!.toStringAsFixed(5);
      final lng = longitude!.toStringAsFixed(5);
      final acc = accuracy != null ? ' ±${accuracy!.round()}m' : '';
      return '$lat, $lng$acc ($method)';
    }
    return 'Detected via BLE ($method)';
  }
}

/// Payload sent to POST /api/detections.
class DetectionPayload {
  final String trackerId;
  final int bleRssi;
  final GpsReading? gps;
  final List<WifiAp> wifiFingerprint;
  final DateTime timestamp;

  const DetectionPayload({
    required this.trackerId,
    required this.bleRssi,
    this.gps,
    required this.wifiFingerprint,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'trackerId': trackerId,
      'bleRssi': bleRssi,
      'wifiFingerprint': wifiFingerprint.map((w) => w.toJson()).toList(),
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
    if (gps != null) {
      map['gps'] = gps!.toJson();
    }
    return map;
  }
}

/// GPS reading from the device.
class GpsReading {
  final double latitude;
  final double longitude;
  final double accuracy;

  const GpsReading({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };
}

/// Single Wi-Fi access point from a scan.
class WifiAp {
  final String bssid;
  final int rssi;

  const WifiAp({required this.bssid, required this.rssi});

  Map<String, dynamic> toJson() => {'bssid': bssid, 'rssi': rssi};
}

/// Response from POST /api/detections.
class DetectionResult {
  final String id;
  final String trackerId;
  final String assetId;
  final String assetName;
  final DetectionPosition position;
  final int bleRssi;
  final DateTime timestamp;

  const DetectionResult({
    required this.id,
    required this.trackerId,
    required this.assetId,
    required this.assetName,
    required this.position,
    required this.bleRssi,
    required this.timestamp,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    final d = json['detection'] as Map<String, dynamic>;
    return DetectionResult(
      id:        d['_id'] as String? ?? '',
      trackerId: d['trackerId'] as String? ?? '',
      assetId:   d['assetId'] as String? ?? '',
      assetName: d['assetName'] as String? ?? '',
      position:  DetectionPosition.fromJson(
                   d['position'] as Map<String, dynamic>),
      bleRssi:   d['bleRssi'] as int? ?? 0,
      timestamp: DateTime.parse(d['timestamp'] as String),
    );
  }
}

/// A BLE device found during scanning — pre-matched to a trackerId.
class BleDetectedDevice {
  final String trackerId;   // matched from asset list
  final String deviceName;  // as advertised by the ESP32
  final int rssi;
  final String? remoteId;   // Bluetooth device address (MAC)
  final DateTime detectedAt; // scan timestamp

  const BleDetectedDevice({
    required this.trackerId,
    required this.deviceName,
    required this.rssi,
    this.remoteId,
    required this.detectedAt,
  });
}
