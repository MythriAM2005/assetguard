import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/asset_model.dart';
import '../models/community_detection_model.dart';
import '../services/community_detection_retrieval_service.dart';
import '../theme/app_theme.dart';

/// Track Asset screen — shows community detection locations on a map.
///
/// Displays:
/// - Interactive map with detection markers
/// - Latest detection info card
/// - Detection history list
/// - Refresh functionality
///
/// Important: AG-001 does not have GPS. The coordinates represent the location
/// of the community phone that detected the tracker.
class TrackAssetScreen extends StatefulWidget {
  final Asset asset;

  const TrackAssetScreen({super.key, required this.asset});

  @override
  State<TrackAssetScreen> createState() => _TrackAssetScreenState();
}

class _TrackAssetScreenState extends State<TrackAssetScreen> {
  List<CommunityDetection> _detections = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetections();
  }

  Future<void> _loadDetections() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detections = await CommunityDetectionRetrievalService.instance
          .getDetectionsForAsset(widget.asset.id);

      if (mounted) {
        setState(() {
          _detections = detections;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('Track ${widget.asset.trackerId}'),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadDetections,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show recovery message if asset is no longer LOST
    if (widget.asset.status != 'LOST') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Asset Recovered',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This asset has been marked as recovered. Community tracking is no longer active.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              if (_detections.isNotEmpty) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      // Allow viewing historical data
                    });
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('View Historical Detections'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading detection history...',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDetections,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_detections.isEmpty) {
      return _buildEmptyState();
    }

    final latest = _detections.first;

    return Column(
      children: [
        // Map takes 40% of screen
        Expanded(
          flex: 4,
          child: _buildMap(latest, _detections),
        ),
        // Details take 60% of screen
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildLatestDetectionCard(latest),
                if (_detections.length > 1) _buildDetectionHistory(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.radar_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No community detections yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'When ${widget.asset.trackerId} is detected by the community, locations will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadDetections,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(CommunityDetection latest, List<CommunityDetection> all) {
    // Filter detections that have valid coordinates
    final detectionsWithLocation = all.where((d) => d.hasLocation).toList();

    if (detectionsWithLocation.isEmpty || !latest.hasLocation) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_outlined,
                  size: 48, color: Color(0xFF9CA3AF)),
              SizedBox(height: 8),
              Text(
                'Location unavailable',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final latestLatLng = LatLng(latest.latitude!, latest.longitude!);

    return FlutterMap(
      options: MapOptions(
        initialCenter: latestLatLng,
        initialZoom: 15.0,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.assetguard',
        ),
        MarkerLayer(
          markers: _buildMarkers(detectionsWithLocation),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<CommunityDetection> detections) {
    final markers = <Marker>[];

    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      if (!detection.hasLocation) continue;

      final isLatest = i == 0;
      final latLng = LatLng(detection.latitude!, detection.longitude!);

      markers.add(
        Marker(
          point: latLng,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showDetectionInfo(detection, isLatest),
            child: Icon(
              Icons.location_on,
              size: isLatest ? 40 : 30,
              color: isLatest ? AppTheme.errorColor : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showDetectionInfo(CommunityDetection detection, bool isLatest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: isLatest ? AppTheme.errorColor : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 8),
            Text(isLatest ? 'Latest Detection' : 'Previous Detection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Time', _formatDateTime(detection.detectedAt)),
            const SizedBox(height: 8),
            _detailRow('Signal', '${detection.rssi} dBm'),
            const SizedBox(height: 8),
            _detailRow('Coordinates',
                '${detection.latitude!.toStringAsFixed(4)}, ${detection.longitude!.toStringAsFixed(4)}'),
            const SizedBox(height: 8),
            Text(
              detection.timeAgo,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestDetectionCard(CommunityDetection latest) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 20,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Last Detected Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.inventory_2_outlined, 'Asset', widget.asset.name),
          const SizedBox(height: 12),
          _infoRow(Icons.nfc_outlined, 'Tracker', widget.asset.trackerId),
          const SizedBox(height: 12),
          if (latest.hasLocation)
            _infoRow(
              Icons.pin_drop_outlined,
              'Coordinates',
              '${latest.latitude!.toStringAsFixed(4)}, ${latest.longitude!.toStringAsFixed(4)}',
            ),
          if (latest.hasLocation) const SizedBox(height: 12),
          _infoRow(
            Icons.access_time_outlined,
            'Detected',
            _formatDateTime(latest.detectedAt),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.signal_cellular_alt_outlined,
            'Signal',
            '${latest.rssi} dBm',
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.people_outlined,
            'Source',
            'Community detection',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last seen ${latest.timeAgo}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionHistory() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Detection History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                '${_detections.length} detections',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._detections.skip(1).take(10).map((detection) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHistoryItem(detection),
            );
          }),
          if (_detections.length > 11)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${_detections.length - 11} more detections',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(CommunityDetection detection) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(detection.detectedAt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (detection.hasLocation) ...[
                      const Icon(Icons.pin_drop, size: 12, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Text(
                        '${detection.latitude!.toStringAsFixed(2)}, ${detection.longitude!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(Icons.signal_cellular_alt, size: 12, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      '${detection.rssi} dBm',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, y • h:mm a').format(dt.toLocal());
  }

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt.toLocal());
  }
}
