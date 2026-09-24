import 'package:flutter/foundation.dart';
import '../models/dashboard_stats_model.dart';
import 'api_service.dart';

/// Service for fetching dashboard statistics.
class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  /// Fetch dashboard statistics for the authenticated user.
  /// 
  /// Returns:
  /// - totalAssets: All assets owned by the user
  /// - lostAssets: Assets currently marked as LOST
  /// - activeTrackingAssets: LOST assets with recent community detections
  Future<DashboardStats> getStats() async {
    try {
      debugPrint('[DashboardService] Fetching dashboard stats');
      
      final response = await ApiService.instance.get('/api/dashboard/stats');
      
      final stats = DashboardStats.fromJson(response);
      
      debugPrint('[DashboardService] Stats loaded: total=${stats.totalAssets}, lost=${stats.lostAssets}, tracking=${stats.activeTrackingAssets}');
      
      return stats;
    } on ApiException catch (e) {
      debugPrint('[DashboardService] API error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[DashboardService] Unexpected error: $e');
      throw Exception('Failed to load dashboard stats');
    }
  }
}
