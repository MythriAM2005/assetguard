import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Handles login, registration, logout, and JWT persistence.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'auth_token';

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Called on app start — restores token from device storage.
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return false;

    ApiService.instance.setToken(token);

    try {
      final data = await ApiService.instance.get('/api/auth/me');
      _currentUser = _userFromJson(data['user'] as Map<String, dynamic>);
      return true;
    } on ApiException catch (e) {
      // Token expired or invalid — clear it
      if (e.statusCode == 401) {
        await _clearToken();
      }
      return false;
    } catch (_) {
      // Server unreachable — don't clear the token; user can retry
      return false;
    }
  }

  /// Returns the message from the server (e.g. "check your email to verify").
  /// 
  /// In development mode (EMAIL_VERIFICATION_ENABLED=false), the server may
  /// return a JWT immediately, allowing the user to skip email verification.
  Future<String> register(String name, String email, String password) async {
    final data = await ApiService.instance.post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    
    // Check if server returned a token (development mode with auto-verify)
    if (data.containsKey('token') && data['token'] != null) {
      // Auto-verified in development mode - handle auth response
      await _handleAuthResponse(data);
      return data['message'] as String? ??
          'Account created and verified. Welcome to AssetGuard AI!';
    }
    
    // Normal production mode - registration without JWT
    // The user must verify their email before they can log in.
    return data['message'] as String? ??
        'Account created. Please check your email to verify your account.';
  }

  /// Called from the deep-link handler with the raw token from the URI.
  /// Calls GET /api/auth/verify-email?token=... and stores the returned JWT.
  /// Returns the success message from the server.
  Future<String> verifyEmailToken(String rawToken) async {
    final data = await ApiService.instance
        .get('/api/auth/verify-email?token=${Uri.encodeComponent(rawToken)}');
    await _handleAuthResponse(data);
    return data['message'] as String? ??
        'Email verified successfully. Welcome to AssetGuard AI!';
  }

  /// POST /api/auth/forgot-password
  /// Always returns a server message regardless of whether the email exists.
  Future<String> forgotPassword(String email) async {
    final data = await ApiService.instance.post('/api/auth/forgot-password', {
      'email': email,
    });
    return data['message'] as String? ??
        'If an account with that email exists, a password-reset link has been sent.';
  }

  /// POST /api/auth/reset-password
  /// Submits the raw token (from the deep link) and the new password.
  /// Returns the server success message. Does NOT log in the user.
  Future<String> resetPassword(String rawToken, String newPassword) async {
    final data = await ApiService.instance.post('/api/auth/reset-password', {
      'token': rawToken,
      'password': newPassword,
    });
    return data['message'] as String? ??
        'Password reset successfully. Please sign in with your new password.';
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.instance.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    await _handleAuthResponse(data);
  }

  Future<void> logout() async {
    _currentUser = null;
    ApiService.instance.setToken(null);
    await _clearToken();
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    _currentUser = _userFromJson(data['user'] as Map<String, dynamic>);
    ApiService.instance.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  UserModel _userFromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? '',
      fullName: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}
