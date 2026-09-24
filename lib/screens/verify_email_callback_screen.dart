import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'login_screen.dart';

/// Shown when the app is opened via the assetguard://verify-email?token=... deep link.
/// Calls the backend, then navigates to the home screen (success) or shows an error.
class VerifyEmailCallbackScreen extends StatefulWidget {
  final String token;

  const VerifyEmailCallbackScreen({super.key, required this.token});

  @override
  State<VerifyEmailCallbackScreen> createState() =>
      _VerifyEmailCallbackScreenState();
}

class _VerifyEmailCallbackScreenState
    extends State<VerifyEmailCallbackScreen> {
  // States: loading | success | expired | invalid | alreadyVerified | error
  _VerifyState _state = _VerifyState.loading;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      final msg = await AuthService.instance.verifyEmailToken(widget.token);
      if (!mounted) return;
      setState(() {
        _state = _VerifyState.success;
        _message = msg;
      });
      // Auto-navigate to home after a short pause
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (_) => false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e.message;
        if (e.statusCode == 410) {
          _state = _VerifyState.expired;
        } else if (e.statusCode == 409) {
          _state = _VerifyState.alreadyVerified;
        } else {
          _state = _VerifyState.invalid;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _VerifyState.error;
        _message =
            'Could not reach the server. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _state == _VerifyState.loading
              ? _buildLoading()
              : _buildResult(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Verifying your email…',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final isSuccess = _state == _VerifyState.success ||
        _state == _VerifyState.alreadyVerified;
    final icon = _stateIcon();
    final color = isSuccess ? AppTheme.successColor : AppTheme.errorColor;
    final title = _stateTitle();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          if (_state == _VerifyState.success) ...[
            const Text(
              'Taking you to the app…',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ] else if (_state == _VerifyState.alreadyVerified) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
                child: const Text('Sign In'),
              ),
            ),
          ] else ...[
            // expired, invalid, error
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
                child: const Text('Back to Sign In'),
              ),
            ),
            const SizedBox(height: 12),
            if (_state == _VerifyState.expired) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  ),
                  child: const Text('Request New Link'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  IconData _stateIcon() {
    switch (_state) {
      case _VerifyState.success:
        return Icons.check_circle_outline;
      case _VerifyState.alreadyVerified:
        return Icons.verified_outlined;
      case _VerifyState.expired:
        return Icons.timer_off_outlined;
      case _VerifyState.invalid:
        return Icons.link_off_outlined;
      case _VerifyState.error:
        return Icons.cloud_off_outlined;
      case _VerifyState.loading:
        return Icons.hourglass_empty;
    }
  }

  String _stateTitle() {
    switch (_state) {
      case _VerifyState.success:
        return 'Email Verified!';
      case _VerifyState.alreadyVerified:
        return 'Already Verified';
      case _VerifyState.expired:
        return 'Link Expired';
      case _VerifyState.invalid:
        return 'Invalid Link';
      case _VerifyState.error:
        return 'Connection Error';
      case _VerifyState.loading:
        return '';
    }
  }
}

enum _VerifyState { loading, success, expired, invalid, alreadyVerified, error }
