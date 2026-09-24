class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? assetId;
  final String? detectionId;
  final String? trackerId;
  final double? latitude;
  final double? longitude;
  final int? rssi;
  final DateTime? detectedAt;
  final String? predictedRoom;
  final double? roomConfidence;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.assetId,
    this.detectionId,
    this.trackerId,
    this.latitude,
    this.longitude,
    this.rssi,
    this.detectedAt,
    this.predictedRoom,
    this.roomConfidence,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      assetId: json['assetId'] as String?,
      detectionId: json['detectionId'] as String?,
      trackerId: json['trackerId'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      rssi: json['rssi'] as int?,
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'] as String)
          : null,
      predictedRoom: json['predictedRoom'] as String?,
      roomConfidence: (json['roomConfidence'] as num?)?.toDouble(),
      read: json['read'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
