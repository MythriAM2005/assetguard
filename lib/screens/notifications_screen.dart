import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'asset_details_screen.dart';
import '../services/asset_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifications = await NotificationService.instance.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications';
          _loading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.read) return;

    final success = await NotificationService.instance.markAsRead(notification.id);
    if (success && mounted) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = AppNotification(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            assetId: notification.assetId,
            detectionId: notification.detectionId,
            trackerId: notification.trackerId,
            latitude: notification.latitude,
            longitude: notification.longitude,
            rssi: notification.rssi,
            detectedAt: notification.detectedAt,
            predictedRoom: notification.predictedRoom,
            roomConfidence: notification.roomConfidence,
            read: true,
            createdAt: notification.createdAt,
          );
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.instance.markAllAsRead();
    if (success && mounted) {
      setState(() {
        _notifications = _notifications.map((n) {
          return AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            assetId: n.assetId,
            detectionId: n.detectionId,
            trackerId: n.trackerId,
            latitude: n.latitude,
            longitude: n.longitude,
            rssi: n.rssi,
            detectedAt: n.detectedAt,
            predictedRoom: n.predictedRoom,
            roomConfidence: n.roomConfidence,
            read: true,
            createdAt: n.createdAt,
          );
        }).toList();
      });
    }
  }

  Future<void> _onNotificationTap(AppNotification notification) async {
    // Mark as read
    await _markAsRead(notification);

    // Navigate to asset details if assetId is available
    if (notification.assetId != null && mounted) {
      try {
        final asset = await AssetService.instance.getAsset(notification.assetId!);
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailsScreen(asset: asset),
            ),
          );
          // Refresh after returning
          _loadNotifications();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load asset details')),
          );
        }
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.read);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When your lost assets are detected,\nyou\'ll see notifications here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final isAssetDetected = notification.type == 'asset_detected';

    return InkWell(
      onTap: () => _onNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read ? AppTheme.cardColor : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.read
                ? const Color(0xFFE8EDF5)
                : AppTheme.primaryColor.withAlpha(77),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAssetDetected
                        ? AppTheme.primaryColor.withAlpha(26)
                        : Colors.grey.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAssetDetected
                        ? Icons.location_on_outlined
                        : Icons.info_outline,
                    size: 20,
                    color: isAssetDetected ? AppTheme.primaryColor : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: notification.read
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          if (!notification.read)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: notification.read
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF374151),
                height: 1.4,
              ),
            ),
            if (isAssetDetected) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (notification.trackerId != null)
                    _buildInfoChip(
                      Icons.sensors_outlined,
                      notification.trackerId!,
                    ),
                  if (notification.predictedRoom != null)
                    _buildRoomChip(
                      notification.predictedRoom!,
                      notification.roomConfidence,
                    ),
                  if (notification.rssi != null)
                    _buildInfoChip(
                      Icons.signal_cellular_alt,
                      '${notification.rssi} dBm',
                    ),
                  if (notification.latitude != null && notification.longitude != null)
                    _buildInfoChip(
                      Icons.pin_drop_outlined,
                      '${notification.latitude!.toStringAsFixed(4)}, ${notification.longitude!.toStringAsFixed(4)}',
                    ),
                  if (notification.detectedAt != null)
                    _buildInfoChip(
                      Icons.access_time_outlined,
                      DateFormat('MMM d, h:mm a').format(notification.detectedAt!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomChip(String room, double? confidence) {
    final confidencePercent = confidence != null ? (confidence * 100).round() : null;
    final displayText = confidencePercent != null 
        ? 'Room $room ($confidencePercent%)'
        : 'Room $room';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
