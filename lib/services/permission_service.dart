import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'community_sensing_service.dart';

/// Manages runtime permission requests for BLE, Location, and Notifications.
/// 
/// Permissions are requested once after successful login and stored.
/// Subsequent logins skip the request if permissions are already granted.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Request all required permissions after successful login.
  /// This method BLOCKS until the user responds to permission dialogs.
  /// 
  /// This should be called after login completes but BEFORE navigating
  /// to the main shell. Navigation should only happen after this completes.
  /// 
  /// After permissions are granted, automatically starts community sensing
  /// in the background.
  Future<void> requestPermissionsAfterLogin(BuildContext context) async {
    // Check if permissions are already granted
    final bluetoothScan = await Permission.bluetoothScan.status;
    final location = await Permission.location.status;

    // If all key permissions are granted, skip the request
    if (bluetoothScan.isGranted && location.isGranted) {
      debugPrint('[Permissions] All permissions already granted');
      // Start community sensing if not already running
      _startCommunitySensingIfNeeded();
      return;
    }

    debugPrint('[Permissions] Requesting permissions after login...');

    // Request permissions and WAIT for user response
    final results = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Log results
    debugPrint('[Permissions] Bluetooth Scan: ${results[Permission.bluetoothScan]}');
    debugPrint('[Permissions] Bluetooth Connect: ${results[Permission.bluetoothConnect]}');
    debugPrint('[Permissions] Location: ${results[Permission.location]}');

    // Check if any critical permissions were denied
    final btScanGranted = results[Permission.bluetoothScan]?.isGranted ?? false;
    final locationGranted = results[Permission.location]?.isGranted ?? false;

    // On Android 11 and below, bluetoothScan might be denied/unknown but
    // scanning still works via legacy permissions. So we only warn if
    // BOTH bluetoothScan AND location are denied.
    if (!btScanGranted && !locationGranted && context.mounted) {
      // Show dialog and wait for user to dismiss it before proceeding
      await _showPermissionDeniedDialog(context);
    } else {
      // Permissions granted - start community sensing automatically
      _startCommunitySensingIfNeeded();
    }
  }

  /// Automatically start community sensing service if permissions are granted
  /// and the service is not already running.
  void _startCommunitySensingIfNeeded() {
    if (CommunitySensingService.instance.isRunning) {
      debugPrint('[Permissions] Community sensing already running');
      return;
    }

    debugPrint('[Permissions] Starting community sensing automatically...');
    
    // Start in background without blocking
    CommunitySensingService.instance.start().then((result) {
      switch (result) {
        case CommunitySensingStartResult.started:
          debugPrint('[Permissions] Community sensing started successfully');
          break;
        case CommunitySensingStartResult.alreadyRunning:
          debugPrint('[Permissions] Community sensing already running');
          break;
        case CommunitySensingStartResult.locationPermissionDenied:
          debugPrint('[Permissions] Cannot start community sensing: location permission denied');
          break;
        case CommunitySensingStartResult.bluetoothPermissionDenied:
          debugPrint('[Permissions] Cannot start community sensing: Bluetooth permission denied');
          break;
        case CommunitySensingStartResult.failed:
          debugPrint('[Permissions] Failed to start community sensing');
          break;
      }
    });
  }

  /// Check if all required permissions are granted.
  /// Used by the scan button to determine if scanning can proceed.
  Future<bool> hasAllPermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.status;
    final location = await Permission.location.status;

    // On Android 12+: need bluetoothScan
    // On Android 11-: need location (legacy BLE permission)
    // We accept either to be compatible with all Android versions
    return bluetoothScan.isGranted || location.isGranted;
  }

  /// Check if location permission is granted (needed for GPS and Wi-Fi)
  Future<bool> hasLocationPermission() async {
    return (await Permission.location.status).isGranted;
  }

  /// Show a dialog explaining why permissions are needed and how to grant them.
  /// Returns a Future that completes when the dialog is dismissed.
  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'AssetGuard needs Bluetooth and Location permissions to:\n\n'
          '• Detect nearby AssetGuard trackers\n'
          '• Help find lost assets\n'
          '• Provide accurate location tracking\n\n'
          'You can grant these permissions later in Settings → Apps → AssetGuard → Permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show a friendly explanation when the user tries to scan without permissions.
  /// This should only appear if they denied permissions initially and
  /// now try to use the scan feature.
  void showPermissionRequiredMessage(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Bluetooth or Location permission is required for scanning.',
        ),
        action: SnackBarAction(
          label: 'Grant',
          onPressed: () async {
            await openAppSettings();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
