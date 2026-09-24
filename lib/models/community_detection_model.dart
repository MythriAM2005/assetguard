/// Model for community detection data from the backend.
///
/// Represents when User B detected a tracker belonging to User A.
/// User B's identity (detectedBy) is never exposed to User A for privacy.
class CommunityDetection {
  final String id;
  final String trackerId;
  final String assetId;
  final int rssi;
  final double? latitude;
  final double? longitude;
  final DateTime detectedAt;
  final DateTime createdAt;

  const CommunityDetection({
    required this.id,
    required this.trackerId,
    required this.assetId,
    required this.rssi,
    this.latitude,
    this.longitude,
    required this.detectedAt,
    required this.createdAt,
  });

  factory CommunityDetection.fromJson(Map<String, dynamic> json) {
    return CommunityDetection(
      id: json['_id'] as String,
      trackerId: json['trackerId'] as String,
      assetId: json['assetId'] as String,
      rssi: json['rssi'] as int,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Check if this detection has valid GPS coordinates
  bool get hasLocation => latitude != null && longitude != null;

  /// Format time relative to now (e.g., "2 minutes ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(detectedAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return '${detectedAt.day}/${detectedAt.month}/${detectedAt.year}';
    }
  }
}
