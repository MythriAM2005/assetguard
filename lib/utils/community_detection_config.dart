/// Configuration constants for BLE Community Detection.
class CommunityDetectionConfig {
  CommunityDetectionConfig._();

  /// Minimum interval (in seconds) between reporting the same tracker.
  /// Prevents flooding the backend with duplicate detections.
  static const int debounceIntervalSeconds = 30;
}
