class DashboardStats {
  final int totalAssets;
  final int lostAssets;
  final int activeTrackingAssets;

  const DashboardStats({
    required this.totalAssets,
    required this.lostAssets,
    required this.activeTrackingAssets,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalAssets: json['totalAssets'] as int? ?? 0,
      lostAssets: json['lostAssets'] as int? ?? 0,
      activeTrackingAssets: json['activeTrackingAssets'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAssets': totalAssets,
      'lostAssets': lostAssets,
      'activeTrackingAssets': activeTrackingAssets,
    };
  }
}
