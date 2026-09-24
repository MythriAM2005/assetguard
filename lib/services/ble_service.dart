import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/detection_model.dart';

/// Wraps flutter_blue_plus for foreground BLE scanning.
///
/// DEBUG MODE (current):
///   - No name / UUID / manufacturer filter — every device is discovered.
///   - Full raw advertisement data is logged to the debug console.
///   - Matching against knownTrackerIds uses BOTH platformName and advName
///     so the ESP32 is found regardless of whether Android cached the name.
///
/// To identify the ESP32, we check (in priority order):
///   1. result.advertisementData.advName  — from the advertisement packet
///   2. result.device.platformName        — from Android's device cache
///   3. Service UUID match against the known ESP32 UUID
class BleService {
  BleService._();
  static final BleService instance = BleService._();

  /// Known ESP32 service UUID for AssetGuard trackers.
  /// This is a secondary identification method when the device name is empty.
  static const String _esp32ServiceUuid =
      '4fafc201-1fb5-459e-8fcc-c5c9c331914b';

  // ── Public scan API ────────────────────────────────────────────────────

  /// Scan for [durationSeconds] seconds.
  ///
  /// In DEBUG mode every discovered device is logged.
  /// [knownTrackerIds] is used to highlight matched devices but does NOT
  /// filter — all devices are returned.  The caller can filter if desired.
  ///
  /// Throws [BleException] if Bluetooth is unavailable.
  Future<List<BleDetectedDevice>> scan({
    required Set<String> knownTrackerIds,
    int durationSeconds = 8,
  }) async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      throw BleException(
        'Bluetooth is not enabled. Please turn on Bluetooth and try again.',
      );
    }

    // key = best available name or MAC address (for unidentified devices)
    final found = <String, BleDetectedDevice>{};

    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        _logResult(r); // always log everything in debug mode

        final key = _resolveKey(r, knownTrackerIds);
        final existing = found[key];
        if (existing == null || r.rssi > existing.rssi) {
          found[key] = BleDetectedDevice(
            trackerId:  key,
            deviceName: _resolveName(r),
            rssi:       r.rssi,
            remoteId:   r.device.remoteId.str,
            detectedAt: DateTime.now(),
          );
        }
      }
    });

    try {
      // Broad scan — no service UUID filter, no name filter
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: durationSeconds),
        androidUsesFineLocation: true, // ensures name resolution on Android
      );
      await FlutterBluePlus.isScanning
          .where((scanning) => !scanning)
          .first
          .timeout(
            Duration(seconds: durationSeconds + 4),
            onTimeout: () => false,
          );
    } finally {
      await sub.cancel();
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    }

    final list = found.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi)); // strongest first

    debugPrint(
      '[BleService] Scan complete. ${list.length} unique device(s) found.',
    );

    return list;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Returns the best name to use as the device key.
  /// Priority: advName > platformName > service UUID hint > remote ID.
  String _resolveKey(ScanResult r, Set<String> knownTrackerIds) {
    final advName      = r.advertisementData.advName.trim();
    final platformName = r.device.platformName.trim();

    // Check advertisement name first — most reliable for unconnected devices
    if (advName.isNotEmpty) {
      if (knownTrackerIds.contains(advName)) return advName;
      return advName;
    }

    // Fall back to cached platform name
    if (platformName.isNotEmpty) {
      if (knownTrackerIds.contains(platformName)) return platformName;
      return platformName;
    }

    // Fall back to service UUID hint (matches our ESP32 UUID)
    final uuids = r.advertisementData.serviceUuids
        .map((u) => u.toString().toLowerCase())
        .toList();
    if (uuids.contains(_esp32ServiceUuid.toLowerCase())) {
      return 'ESP32-${r.device.remoteId.str.substring(
        r.device.remoteId.str.length > 5
            ? r.device.remoteId.str.length - 5
            : 0,
      )}';
    }

    // Last resort — use the MAC / remote ID
    return r.device.remoteId.str;
  }

  String _resolveName(ScanResult r) {
    final adv = r.advertisementData.advName.trim();
    if (adv.isNotEmpty) return adv;
    final platform = r.device.platformName.trim();
    if (platform.isNotEmpty) return platform;
    return r.device.remoteId.str;
  }

  /// Log the full raw advertisement data for debugging.
  void _logResult(ScanResult r) {
    final adv = r.advertisementData;
    final uuids = adv.serviceUuids.map((u) => u.toString()).join(', ');
    final mfrData = adv.manufacturerData.entries
        .map((e) => '0x${e.key.toRadixString(16)}: ${e.value}')
        .join(', ');

    debugPrint(
      '[BleService] Device found:\n'
      '  remoteId     : ${r.device.remoteId}\n'
      '  platformName : "${r.device.platformName}"\n'
      '  advName      : "${adv.advName}"\n'
      '  rssi         : ${r.rssi} dBm\n'
      '  serviceUuids : [$uuids]\n'
      '  mfrData      : {$mfrData}',
    );
  }
}

/// Thrown when BLE is unavailable or a scan error occurs.
class BleException implements Exception {
  final String message;
  const BleException(this.message);
  @override
  String toString() => message;
}
