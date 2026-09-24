import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../models/detection_model.dart';

/// Provides GPS position and Wi-Fi fingerprint for the hybrid
/// detection payload.  All methods are graceful — they return null
/// instead of throwing when a sensor is unavailable or denied.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // ── GPS ──────────────────────────────────────────────────────────────────

  /// Returns the current GPS fix, or null if unavailable / denied.
  /// Uses the Android fused location provider (high accuracy).
  Future<GpsReading?> getPosition() async {
    try {
      final status = await Permission.location.status;
      if (!status.isGranted) return null;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return GpsReading(
        latitude:  pos.latitude,
        longitude: pos.longitude,
        accuracy:  pos.accuracy,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Wi-Fi fingerprint ─────────────────────────────────────────────────────

  /// Returns a list of visible Wi-Fi APs with BSSID and RSSI.
  /// Returns an empty list if the permission is denied or the scan fails.
  ///
  /// Note: Android throttles Wi-Fi scans to ~4 per 2 minutes when the
  /// screen is off.  For foreground use this is not a concern.
  Future<List<WifiAp>> getWifiFingerprint() async {
    try {
      // wifi_scan requires LOCATION permission (fine) on Android
      final locStatus = await Permission.location.status;
      if (!locStatus.isGranted) return [];

      final canScan = await WiFiScan.instance
          .canStartScan(askPermissions: false);
      if (canScan != CanStartScan.yes) return [];

      await WiFiScan.instance.startScan();

      final canGet = await WiFiScan.instance
          .canGetScannedResults(askPermissions: false);
      if (canGet != CanGetScannedResults.yes) return [];

      final results = await WiFiScan.instance.getScannedResults();

      return results
          .where((ap) => ap.bssid.isNotEmpty)
          .map((ap) => WifiAp(bssid: ap.bssid, rssi: ap.level))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Permission helpers ────────────────────────────────────────────────────

  /// Request all permissions needed for hybrid detection.
  /// Returns true only if BLE scan permission is granted.
  /// Location permission is requested but its result does NOT block BLE.
  Future<bool> requestPermissions() async {
    // Request everything in one shot
    final results = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // BLE scanning requires bluetoothScan on Android 12+.
    // On Android 11 and below bluetoothScan status will be unknown/denied
    // but scanning works via the legacy BLUETOOTH permission — so we allow
    // the scan to proceed if either bluetoothScan OR location is granted.
    final btGranted  = results[Permission.bluetoothScan]?.isGranted ?? false;
    final locGranted = results[Permission.location]?.isGranted ?? false;

    return btGranted || locGranted;
  }

  /// True if fine location permission is already granted.
  Future<bool> get hasLocationPermission async =>
      (await Permission.location.status).isGranted;

  /// True if BLE scan permission is granted (Android 12+).
  Future<bool> get hasBluetoothPermission async =>
      (await Permission.bluetoothScan.status).isGranted;
}
