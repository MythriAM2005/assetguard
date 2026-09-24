import '../config/environment.dart';

/// API configuration for AssetGuard.
///
/// For production deployment, build with:
///   flutter build apk \
///     --dart-define=API_URL=https://your-backend-url \
///     --dart-define=ML_API_URL=https://wifi-server-sl6b.onrender.com
///
/// See lib/config/environment.dart for configuration details.
class ApiConfig {
  /// Node.js backend base URL (auth, assets, detections, community features)
  static String get baseUrl => Environment.apiBaseUrl;
  
  /// Python ML server base URL (room prediction only)
  static String get mlBaseUrl => Environment.mlApiBaseUrl;
  
  static Duration get timeout => Environment.timeout;
  static Duration get mlTimeout => Environment.mlTimeout;
}
