class Asset {
  final String id;
  String name;
  String category;
  String description;
  String trackerId;
  String status; // 'ACTIVE', 'LOST', 'RECOVERED'
  String lastDetectedLocation;
  String lastDetectedTime;

  Asset({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.trackerId,
    required this.status,
    required this.lastDetectedLocation,
    required this.lastDetectedTime,
  });

  /// Deserialise from API JSON (MongoDB document).
  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      trackerId: json['trackerId'] as String? ?? '',
      status: (json['status'] as String? ?? 'ACTIVE').toUpperCase(),
      lastDetectedLocation: json['lastDetectedLocation'] as String? ?? 'Not yet detected',
      lastDetectedTime: json['lastDetectedTime'] != null
          ? _formatTime(json['lastDetectedTime'] as String)
          : 'Not yet detected',
    );
  }

  /// Serialise to JSON for create/update API calls.
  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'description': description,
        'trackerId': trackerId,
        'status': status,
      };

  Asset copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? trackerId,
    String? status,
    String? lastDetectedLocation,
    String? lastDetectedTime,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      trackerId: trackerId ?? this.trackerId,
      status: status ?? this.status,
      lastDetectedLocation: lastDetectedLocation ?? this.lastDetectedLocation,
      lastDetectedTime: lastDetectedTime ?? this.lastDetectedTime,
    );
  }

  static String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dtDay = DateTime(dt.year, dt.month, dt.day);

      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour:$minute $ampm';

      if (dtDay == today) return 'Today, $timeStr';
      final yesterday = today.subtract(const Duration(days: 1));
      if (dtDay == yesterday) return 'Yesterday, $timeStr';
      return '${dt.day}/${dt.month}/${dt.year}, $timeStr';
    } catch (_) {
      return isoString;
    }
  }
}
