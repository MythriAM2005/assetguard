/// Environment configuration for AssetGuard.
///
/// Allows configuring API URLs at build time using --dart-define.
///
/// Usage:
///   Development build:
///     flutter build apk
///
///   Production build:
///     flutter build apk \
///       --dart-define=API_URL=https://your-backend.com \
///       --dart-define=ML_API_URL=https://wifi-server-sl6b.onrender.com
///
class Environment {
  /// Node.js Backend API base URL (for auth, assets, detections, etc.)
  /// 
  /// Set at build time with --dart-define=API_URL=url
  /// 
  /// Default is the production backend server.
  /// Can be overridden at build time for testing.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://assetguard-qynw.onrender.com',
  );

  /// Python ML Server API base URL (for room prediction)
  /// 
  /// Set at build time with --dart-define=ML_API_URL=url
  /// 
  /// Production: https://wifi-server-sl6b.onrender.com
  /// Development: http://127.0.0.1:8000
  static const String mlApiBaseUrl = String.fromEnvironment(
    'ML_API_URL',
    defaultValue: 'https://wifi-server-sl6b.onrender.com',
  );

  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 15);

  /// ML API timeout (longer for cold starts)
  static const Duration mlTimeout = Duration(seconds: 30);

  /// Check if using default (production) configuration
  static bool get isDefaultConfig => apiBaseUrl == 'https://assetguard-qynw.onrender.com';
}
