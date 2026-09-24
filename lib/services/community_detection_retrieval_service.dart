import 'package:flutter/foundation.dart';
import '../models/community_detection_model.dart';
import 'api_service.dart';

/// Service for retrieving community detection history.
///
/// Used by the Track Asset feature to fetch and display detection locations.
class CommunityDetectionRetrievalService {
  CommunityDetectionRetrievalService._();
  static final CommunityDetectionRetrievalService instance =
      CommunityDetectionRetrievalService._();

  /// Fetch all community detections for a specific asset owned by the authenticated user.
  ///
  /// Returns detections sorted by newest first.
  /// Only returns detections for assets owned by the current user (security enforced by backend).
  Future<List<CommunityDetection>> getDetectionsForAsset(String assetId) async {
    try {
      debugPrint('[CommunityDetectionRetrieval] Fetching detections for asset: $assetId');

      final response = await ApiService.instance.get(
        '/api/community/detections/asset/$assetId',
      );

      final detections = (response['detections'] as List)
          .map((json) => CommunityDetection.fromJson(json))
          .toList();

      debugPrint('[CommunityDetectionRetrieval] Loaded ${detections.length} detections');

      return detections;
    } on ApiException catch (e) {
      debugPrint('[CommunityDetectionRetrieval] API error: ${e.message}');
      throw Exception('Failed to load detections: ${e.message}');
    } catch (e) {
      debugPrint('[CommunityDetectionRetrieval] Unexpected error: $e');
      throw Exception('Failed to load detections');
    }
  }

  /// Get the latest detection for an asset (convenience method)
  Future<CommunityDetection?> getLatestDetectionForAsset(String assetId) async {
    final detections = await getDetectionsForAsset(assetId);
    return detections.isEmpty ? null : detections.first;
  }
}
