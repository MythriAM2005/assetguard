import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../models/community_detection_model.dart';
import '../services/asset_service.dart';
import '../services/api_service.dart';
import '../services/community_detection_retrieval_service.dart';
import '../theme/app_theme.dart';
import 'edit_asset_screen.dart';
import 'track_asset_screen.dart';

class AssetDetailsScreen extends StatefulWidget {
  final Asset asset;

  const AssetDetailsScreen({super.key, required this.asset});

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> {
  late Asset _asset;
  bool _loading = false;
  CommunityDetection? _latestDetection;

  @override
  void initState() {
    super.initState();
    _asset = widget.asset;
    _loadLatestDetection();
  }

  Future<void> _loadLatestDetection() async {
    try {
      final detection = await CommunityDetectionRetrievalService.instance
          .getLatestDetectionForAsset(_asset.id);
      if (mounted) {
        setState(() => _latestDetection = detection);
      }
    } catch (e) {
      // Silently fail — not critical for asset details view
      debugPrint('[AssetDetails] Failed to load latest detection: $e');
    }
  }

  IconData get _categoryIcon {
    switch (_asset.category.toLowerCase()) {
      case 'bag':
        return Icons.backpack_outlined;
      case 'laptop':
        return Icons.laptop_outlined;
      case 'id card':
        return Icons.badge_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'phone':
        return Icons.smartphone_outlined;
      case 'electronics':
        return Icons.headphones_outlined;
      default:
        return Icons.devices_other_outlined;
    }
  }

  // ── Edit ──────────────────────────────────────────────────────────────────

  Future<void> _openEdit() async {
    final updated = await Navigator.push<Asset>(
      context,
      MaterialPageRoute(builder: (_) => EditAssetScreen(asset: _asset)),
    );
    if (updated != null && mounted) {
      setState(() => _asset = updated);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _deleteAsset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Delete Asset'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${_asset.name}"?\n\n'
          'This action cannot be undone. The asset will be removed from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await AssetService.instance.deleteAsset(_asset.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_asset.name}" has been deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop back to asset list; pass true so caller refreshes
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete asset. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Report Lost / Recovered ───────────────────────────────────────────────

  Future<void> _reportLost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Report as Lost'),
          ],
        ),
        content: Text(
          'Are you sure you want to report "${_asset.name}" as lost?\n\n'
          'This will notify the campus community network.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Report Lost'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final updated = await AssetService.instance.markLost(_asset.id);
      if (mounted) {
        setState(() => _asset = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asset reported as lost. Community alerted.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRecovered() async {
    setState(() => _loading = true);
    try {
      final updated = await AssetService.instance.markRecovered(_asset.id);
      if (mounted) {
        setState(() => _asset = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asset marked as recovered.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Return true to signal that recovery was successful
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _trackAsset() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackAssetScreen(asset: _asset),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final statusColor = _asset.status.statusColor;
    final statusBg = _asset.status.statusBgColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: _loading ? null : _openEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            color: AppTheme.errorColor,
            onPressed: _loading ? null : _deleteAsset,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryDark,
                          AppTheme.primaryColor
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(26),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(_categoryIcon,
                                  color: Colors.white, size: 28),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _asset.status[0].toUpperCase() +
                                    _asset.status
                                        .substring(1)
                                        .toLowerCase(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _asset.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _asset.category,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(204)),
                        ),
                        const SizedBox(height: 16),
                        _trackerIdChip(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('Asset Information'),
                  const SizedBox(height: 12),
                  _infoCard([
                    _infoRow(Icons.label_outline, 'Asset ID', _asset.id),
                    _infoRow(Icons.category_outlined, 'Category',
                        _asset.category),
                    _infoRow(
                        Icons.description_outlined,
                        'Description',
                        _asset.description.isEmpty
                            ? '—'
                            : _asset.description),
                  ]),

                  const SizedBox(height: 20),
                  _sectionTitle('Last Known Location'),
                  const SizedBox(height: 12),
                  _infoCard([
                    _infoRow(
                      Icons.location_on_outlined,
                      'Location',
                      _latestDetection != null && _latestDetection!.hasLocation
                          ? '${_latestDetection!.latitude!.toStringAsFixed(4)}, ${_latestDetection!.longitude!.toStringAsFixed(4)}'
                          : 'No community detections yet',
                    ),
                    _infoRow(
                      Icons.access_time_outlined,
                      'Time',
                      _latestDetection != null
                          ? _formatDetectionTime(_latestDetection!.detectedAt)
                          : '—',
                    ),
                    _infoRow(
                      Icons.signal_cellular_alt_outlined,
                      'Signal',
                      _latestDetection != null
                          ? '${_latestDetection!.rssi} dBm (Community detected)'
                          : '—',
                    ),
                  ]),

                  const SizedBox(height: 20),
                  _sectionTitle('Tracker Details'),
                  const SizedBox(height: 12),
                  _infoCard([
                    _infoRow(Icons.nfc_outlined, 'Tracker ID',
                        _asset.trackerId),
                    _infoRow(
                        Icons.bluetooth_outlined, 'Protocol', 'BLE 5.0'),
                    _infoRow(Icons.battery_charging_full_outlined,
                        'Battery', 'Not reported by tracker'),
                  ]),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _trackAsset,
                      icon: const Icon(Icons.radar_outlined, size: 20),
                      label: const Text('Track Asset'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_asset.status != 'LOST')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _reportLost,
                        icon: const Icon(Icons.report_problem_outlined,
                            size: 20),
                        label: const Text('Report as Lost'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(
                              color: AppTheme.errorColor),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _markRecovered,
                        icon: const Icon(Icons.check_circle_outline,
                            size: 20),
                        label: const Text('Mark as Recovered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _trackerIdChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nfc_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _asset.trackerId,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: rows
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value,
                  if (e.key < rows.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetectionTime(DateTime dt) {
    try {
      final local = dt.toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dtDay = DateTime(local.year, local.month, local.day);

      final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
      final minute = local.minute.toString().padLeft(2, '0');
      final ampm = local.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour:$minute $ampm';

      if (dtDay == today) return 'Today, $timeStr';
      final yesterday = today.subtract(const Duration(days: 1));
      if (dtDay == yesterday) return 'Yesterday, $timeStr';
      return '${local.day}/${local.month}/${local.year}, $timeStr';
    } catch (_) {
      return dt.toString();
    }
  }
}
