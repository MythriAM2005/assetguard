import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../models/detection_model.dart';
import '../services/asset_service.dart';
import '../services/ble_service.dart';
import '../services/detection_service.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/api_service.dart';
import '../services/wifi_scan_service.dart';
import '../services/room_prediction_service.dart';
import '../services/community_sensing_service.dart';
import '../services/community_detection_service.dart';
import '../models/room_prediction_model.dart';
import '../theme/app_theme.dart';

class NearbyDevicesScreen extends StatefulWidget {
  const NearbyDevicesScreen({super.key});

  @override
  State<NearbyDevicesScreen> createState() => _NearbyDevicesScreenState();
}

class _NearbyDevicesScreenState extends State<NearbyDevicesScreen>
    with SingleTickerProviderStateMixin {

  // ── State ─────────────────────────────────────────────────────────────────

  List<Asset> _registeredAssets = [];
  bool _loadingAssets = true;

  bool _scanning = false;
  List<BleDetectedDevice> _scannedDevices = [];
  String? _scanError;

  // Per-device submission state
  final Map<String, bool>     _submitting = {};
  final Map<String, String>   _submitError = {};
  final Map<String, DetectionResult> _results = {};

  // ── Wi-Fi Localization Test state ─────────────────────────────────────────
  bool _wifiScanning = false;
  List<NieAccessPoint> _nieAps = [];
  String? _wifiError;

  // ── Room Prediction state ─────────────────────────────────────────────────
  bool _predicting = false;
  RoomPredictionResult? _prediction;
  String? _predictionError;

  // ── Community Sensing state ───────────────────────────────────────────────
  bool _communitySensingEnabled = false;
  bool _startingCommunitySensing = false;
  String? _communitySensingError;

  // ── Community Detection state ──────────────────────────────────────────────
  int _communityDetectionsReported = 0;

  // Pulse animation for the scanner circle
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadAssets();
    // Check if Community Sensing is already running
    _communitySensingEnabled = CommunitySensingService.instance.isRunning;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Load registered assets ────────────────────────────────────────────────

  Future<void> _loadAssets() async {
    setState(() => _loadingAssets = true);
    try {
      _registeredAssets = await AssetService.instance.getAssets();
    } catch (_) {
      _registeredAssets = [];
    } finally {
      if (mounted) setState(() => _loadingAssets = false);
    }
  }

  // ── BLE scan ──────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _scanError = null;
      _scannedDevices = [];
      _submitting.clear();
      _submitError.clear();
      _results.clear();
      _communityDetectionsReported = 0; // reset community detection counter
    });

    // Check if permissions are already granted
    // Do NOT request them here - they should have been requested at login
    final hasPermissions = await PermissionService.instance.hasAllPermissions();
    if (!hasPermissions && mounted) {
      setState(() {
        _scanning = false;
        _scanError =
            'Bluetooth or Location permission is required for BLE scanning. '
            'Please grant permissions in Settings → Apps → AssetGuard → Permissions.';
      });
      // Show a helpful message with an option to open settings
      PermissionService.instance.showPermissionRequiredMessage(context);
      return;
    }

    try {
      // Pass ALL known tracker IDs — the service now returns every device
      // it sees, but prioritises matched ones for display.
      final knownIds = _registeredAssets.map((a) => a.trackerId).toSet();
      final devices = await BleService.instance.scan(
        knownTrackerIds: knownIds,
        durationSeconds: 8,
      );
      if (mounted) {
        setState(() {
          _scannedDevices = devices;
          _scanning = false;
        });

        // Report community detections for LOST assets
        await _reportCommunityDetections(devices);
      }
    } on BleException catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanError = 'Scan failed: $e';
        });
      }
    }
  }

  // ── Submit detection ──────────────────────────────────────────────────────

  Future<void> _submitDetection(BleDetectedDevice device) async {
    setState(() {
      _submitting[device.trackerId] = true;
      _submitError.remove(device.trackerId);
    });

    try {
      // Collect GPS + Wi-Fi concurrently
      final results = await Future.wait([
        LocationService.instance.getPosition(),
        LocationService.instance.getWifiFingerprint(),
      ]);

      final gps      = results[0] as GpsReading?;
      final wifiAps  = results[1] as List<WifiAp>;

      final result = await DetectionService.instance.submitDetection(
        trackerId:       device.trackerId,
        bleRssi:         device.rssi,
        gps:             gps,
        wifiFingerprint: wifiAps,
      );

      if (mounted) {
        setState(() => _results[device.trackerId] = result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitError[device.trackerId] = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitError[device.trackerId] =
            'Detection failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting[device.trackerId] = false);
      }
    }
  }

  // ── Report community detections ───────────────────────────────────────────

  Future<void> _reportCommunityDetections(
      List<BleDetectedDevice> devices) async {
    int reported = 0;

    for (final device in devices) {
      // Report ALL detected AssetGuard trackers, regardless of ownership.
      // The backend will:
      // 1. Look up the asset globally by trackerId (cross-user lookup)
      // 2. Verify the asset status is LOST
      // 3. Create a CommunityDetection record linking to the owner's asset
      // 4. Reject if not found or not LOST
      //
      // This enables cross-user community detection for lost assets.

      // Check debounce
      if (!CommunityDetectionService.instance.shouldReport(device.trackerId)) {
        debugPrint(
          '[CommunityDetection] Skipping ${device.trackerId} '
          '(debounced)',
        );
        continue;
      }

      // Attempt to report
      final success = await CommunityDetectionService.instance
          .reportDetection(
        trackerId: device.trackerId,
        rssi: device.rssi,
        remoteId: device.remoteId,
        detectedAt: device.detectedAt,
      );

      if (success) {
        reported++;
      }
    }

    if (mounted && reported > 0) {
      setState(() => _communityDetectionsReported = reported);
      debugPrint('[CommunityDetection] Reported $reported detection(s)');
    }
  }

  // ── Wi-Fi Localization Test ───────────────────────────────────────────────

  Future<void> _startWifiScan() async {
    setState(() {
      _wifiScanning = true;
      _wifiError = null;
      _nieAps = [];
    });

    final result = await WifiScanService.instance.scanNieAccessPoints();

    if (!mounted) return;

    if (result is WifiScanSuccess) {
      setState(() {
        _nieAps = result.accessPoints;
        _wifiScanning = false;
        if (result.accessPoints.isEmpty) {
          _wifiError =
              'No NIE-STUDENTS or NIE-STAFF networks found nearby.';
        }
      });
    } else if (result is WifiScanFailure) {
      setState(() {
        _wifiScanning = false;
        _wifiError = result.reason;
      });
    }
  }

  // ── Room Prediction ───────────────────────────────────────────────────────

  Future<void> _predictRoom() async {
    if (_predicting) return; // prevent duplicate simultaneous requests

    if (_nieAps.isEmpty) {
      setState(() {
        _predictionError =
            'No Wi-Fi data available. Tap "Scan Wi-Fi" first.';
        _prediction = null;
      });
      return;
    }

    setState(() {
      _predicting = true;
      _predictionError = null;
      _prediction = null;
    });

    try {
      // Convert NieAccessPoint list → { bssid: rssiDbm }
      final fingerprint = {
        for (final ap in _nieAps) ap.bssid: ap.rssiDbm,
      };

      final result = await RoomPredictionService.instance
          .predictRoom(fingerprint);

      if (mounted) setState(() => _prediction = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _predictionError = e.message);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _predictionError = 'Prediction failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  // ── Community Sensing ─────────────────────────────────────────────────────

  Future<void> _toggleCommunitySensing(bool enable) async {
    // Prevent toggling while already in progress
    if (_startingCommunitySensing) return;

    setState(() {
      _startingCommunitySensing = true;
      _communitySensingError = null;
    });

    try {
      if (enable) {
        final result = await CommunitySensingService.instance.start();

        if (!mounted) return;

        switch (result) {
          case CommunitySensingStartResult.started:
            setState(() {
              _communitySensingEnabled = true;
              _communitySensingError = null;
            });
            break;

          case CommunitySensingStartResult.alreadyRunning:
            setState(() {
              _communitySensingEnabled = true;
              _communitySensingError = null;
            });
            break;

          case CommunitySensingStartResult.locationPermissionDenied:
            setState(() {
              _communitySensingEnabled = false;
              _communitySensingError =
                  'Location permission is required for community sensing. '
                  'Please grant it in Settings → App Permissions.';
            });
            break;

          case CommunitySensingStartResult.bluetoothPermissionDenied:
            setState(() {
              _communitySensingEnabled = false;
              _communitySensingError =
                  'Bluetooth permission is required for community sensing. '
                  'Please grant it in Settings → App Permissions.';
            });
            break;

          case CommunitySensingStartResult.failed:
            setState(() {
              _communitySensingEnabled = false;
              _communitySensingError =
                  'Failed to start community sensing. Please try again.';
            });
            break;
        }
      } else {
        await CommunitySensingService.instance.stop();
        if (mounted) {
          setState(() {
            _communitySensingEnabled = false;
            _communitySensingError = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _communitySensingEnabled = false;
          _communitySensingError =
              'Community sensing error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _startingCommunitySensing = false);
      }
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  String _assetNameFor(String trackerId) {
    try {
      return _registeredAssets
          .firstWhere((a) => a.trackerId == trackerId)
          .name;
    } catch (_) {
      return trackerId;
    }
  }

  Color _rssiColor(int rssi) {
    if (rssi >= -60) return AppTheme.successColor;
    if (rssi >= -75) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _rssiLabel(int rssi) {
    if (rssi >= -60) return 'Strong';
    if (rssi >= -75) return 'Moderate';
    return 'Weak';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Devices'),
        actions: [
          if (_scannedDevices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_scannedDevices.length} Found',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loadingAssets
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _infoCard(),
                  const SizedBox(height: 24),
                  _scannerCircle(),
                  const SizedBox(height: 24),
                  _scanButton(),
                  if (_scanError != null) ...[
                    const SizedBox(height: 16),
                    _errorBanner(_scanError!),
                  ],
                  if (_scannedDevices.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _deviceListHeader(),
                    const SizedBox(height: 12),
                    ..._scannedDevices.map(_buildDeviceTile),
                    // Community detection indicator
                    if (_communityDetectionsReported > 0) ...[
                      const SizedBox(height: 12),
                      _buildCommunityDetectionIndicator(),
                    ],
                  ] else if (!_scanning && _scanError == null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Tap "Scan for Devices" to discover all nearby\nBLE devices including your ESP32 trackers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Wi-Fi Localization Test ───────────────────────────
                  _buildWifiSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(51)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Scanning discovers all nearby BLE devices. '
              'Devices matching your registered Tracker IDs '
              '(e.g. "AG-001") are highlighted. '
              'Raw scan data is logged to the debug console.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor.withAlpha(230),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerCircle() {
    return ScaleTransition(
      scale:
          _scanning ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _scanning
              ? AppTheme.primaryColor.withAlpha(20)
              : const Color(0xFFF0F4FF),
          border: Border.all(
            color: _scanning
                ? AppTheme.primaryColor.withAlpha(102)
                : const Color(0xFFE8EDF5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching_outlined,
              size: 44,
              color: _scanning
                  ? AppTheme.primaryColor
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 8),
            Text(
              _scanning ? 'Scanning…' : 'BLE Scanner',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _scanning
                    ? AppTheme.primaryColor
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _scanning ? null : _startScan,
        icon: _scanning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.bluetooth_searching_outlined, size: 20),
        label: Text(
            _scanning ? 'Scanning for devices…' : 'Scan for Devices'),
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.errorColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Widget _deviceListHeader() {
    return Row(
      children: [
        const Text(
          'Detected Trackers',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const Spacer(),
        Text(
          '${_scannedDevices.length} device${_scannedDevices.length == 1 ? '' : 's'}',
          style:
              const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildDeviceTile(BleDetectedDevice device) {
    final color       = _rssiColor(device.rssi);
    final assetName   = _assetNameFor(device.trackerId);
    final submitting  = _submitting[device.trackerId] ?? false;
    final submitErr   = _submitError[device.trackerId];
    final result      = _results[device.trackerId];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + name + RSSI
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.sensors_outlined,
                    color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assetName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      device.trackerId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${device.rssi} dBm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(_rssiLabel(device.rssi),
                      style:
                          TextStyle(fontSize: 11, color: color)),
                ],
              ),
            ],
          ),

          // Detection result or error
          if (result != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.successColor.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppTheme.successColor, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      result.position.summary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (submitErr != null) ...[
            const SizedBox(height: 10),
            _errorBanner(submitErr),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _submitDetection(device),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    submitting ? null : () => _submitDetection(device),
                icon: submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white),
                      )
                    : const Icon(Icons.upload_outlined, size: 16),
                label: Text(submitting
                    ? 'Submitting…'
                    : 'Submit Detection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Wi-Fi Localization Test UI ────────────────────────────────────────────

  Widget _buildWifiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        const Divider(height: 1),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.wifi_outlined,
                  color: Color(0xFF8B5CF6), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Wi-Fi Localization Test',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Scans for NIE-STUDENTS and NIE-STAFF access points. '
          'Raw RSSI values (dBm) are displayed without conversion.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
        ),
        const SizedBox(height: 14),

        // Scan button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _wifiScanning ? null : _startWifiScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            icon: _wifiScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.wifi_find_outlined, size: 20),
            label: Text(_wifiScanning ? 'Scanning Wi-Fi…' : 'Scan Wi-Fi'),
          ),
        ),

        const SizedBox(height: 16),

        // ── Community Sensing Toggle ────────────────────────────────
        _buildCommunitySensingToggle(),

        // Community Sensing error
        if (_communitySensingError != null) ...[
          const SizedBox(height: 12),
          _errorBanner(_communitySensingError!),
        ],

        // Error
        if (_wifiError != null) ...[
          const SizedBox(height: 12),
          _errorBanner(_wifiError!),
        ],

        // Results
        if (_nieAps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Detected Access Points',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                '${_nieAps.length} AP${_nieAps.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._nieAps.map(_buildApTile),
          const SizedBox(height: 14),

          // ── Predict Room button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _predicting ? null : _predictRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
              ),
              icon: _predicting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.room_outlined, size: 20),
              label: Text(_predicting ? 'Predicting…' : 'Predict Room'),
            ),
          ),

          // ── Prediction error ───────────────────────────────────────
          if (_predictionError != null) ...[
            const SizedBox(height: 12),
            _errorBanner(_predictionError!),
          ],

          // ── Prediction result ──────────────────────────────────────
          if (_prediction != null) ...[
            const SizedBox(height: 14),
            _buildPredictionResult(_prediction!),
          ],
        ],
      ],
    );
  }

  Widget _buildApTile(NieAccessPoint ap) {
    final rssi  = ap.rssiDbm;
    final color = _rssiColor(rssi);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          // Signal icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.wifi_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          // SSID + BSSID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ap.ssid,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ap.bssid,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // Raw RSSI
          Text(
            '$rssi dBm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ── Prediction result card ────────────────────────────────────────────────

  Widget _buildPredictionResult(RoomPredictionResult p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.successColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.room_outlined,
                  color: AppTheme.successColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Room Prediction',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Predicted room
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Room ${p.predictedRoom}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  height: 1,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  p.confidencePercent,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),

          // Top 3 if available
          if (p.top3.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Top predictions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            ...p.top3.asMap().entries.map((e) {
              final rank  = e.key + 1;
              final entry = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '$rank. ',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    Text(
                      'Room ${entry.room}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      entry.probabilityPercent,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Community Sensing Toggle ──────────────────────────────────────────────

  Widget _buildCommunitySensingToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _communitySensingEnabled
            ? const Color(0xFF10B981).withAlpha(15)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _communitySensingEnabled
              ? const Color(0xFF10B981).withAlpha(51)
              : const Color(0xFFE8EDF5),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _communitySensingEnabled
                  ? const Color(0xFF10B981).withAlpha(20)
                  : const Color(0xFF6B7280).withAlpha(20),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _communitySensingEnabled
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_off_outlined,
              color: _communitySensingEnabled
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B7280),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Sensing',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _communitySensingEnabled
                      ? 'Background Wi-Fi scanning active'
                      : 'Help improve location accuracy',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Toggle switch
          if (_startingCommunitySensing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: _communitySensingEnabled,
              onChanged: _toggleCommunitySensing,
              activeTrackColor: const Color(0xFF10B981).withAlpha(102),
              activeThumbColor: const Color(0xFF10B981),
            ),
        ],
      ),
    );
  }

  // ── Community Detection Indicator ─────────────────────────────────────────

  Widget _buildCommunityDetectionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline,
            color: Color(0xFF10B981),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Community detections reported: $_communityDetectionsReported',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF10B981),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

