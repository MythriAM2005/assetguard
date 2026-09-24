import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';

/// Opened via the assetguard://reset-password?token=... deep link.
/// Collects new password, calls the backend, then navigates to Login.
class ResetPasswordScreen extends StatefulWidget {
  /// Raw token extracted from the deep link — never displayed to the user.
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  _ResetState _state = _ResetState.form;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      await AuthService.instance.resetPassword(
        widget.token,
        _passwordCtrl.text,
      );
      if (mounted) setState(() => _state = _ResetState.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 410) {
        setState(() {
          _state = _ResetState.expired;
          _errorMessage = e.message;
        });
      } else if (e.statusCode == 400) {
        setState(() {
          _state = _ResetState.invalid;
          _errorMessage = e.message;
        });
      } else {
        setState(() {
          _state = _ResetState.error;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _ResetState.error;
        _errorMessage =
            'Could not reach the server. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Reset Password'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ResetState.success:
        return _buildSuccess();
      case _ResetState.expired:
        return _buildExpired();
      case _ResetState.invalid:
      case _ResetState.error:
        return _buildError();
      case _ResetState.form:
        return _buildForm();
    }
  }

  // ── Form state ──────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Set a new password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a strong password for your AssetGuard AI account.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          CustomTextField(
            label: 'New Password',
            hint: 'At least 6 characters',
            controller: _passwordCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please enter a new password';
              }
              if (v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          CustomTextField(
            label: 'Confirm New Password',
            hint: 'Re-enter your new password',
            controller: _confirmCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Please confirm your new password';
              }
              if (v != _passwordCtrl.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Reset Password'),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _goToLogin,
              child: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success state ───────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 44,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Password Reset!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Your password has been reset successfully.\nSign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF4B5563),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _goToLogin,
            child: const Text('Sign In'),
          ),
        ),
      ],
    );
  }

  // ── Expired state ───────────────────────────────────────────────────────

  Widget _buildExpired() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.timer_off_outlined,
            size: 44,
            color: AppTheme.warningColor,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Link Expired',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage.isNotEmpty
              ? _errorMessage
              : 'This password-reset link has expired. Please request a new one.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF4B5563),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _goToLogin,
            child: const Text('Back to Sign In'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Use the "Forgot Password?" link on the Sign In screen to request a new link.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ── Invalid / Error state ───────────────────────────────────────────────

  Widget _buildError() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _state == _ResetState.error
                ? Icons.cloud_off_outlined
                : Icons.link_off_outlined,
            size: 44,
            color: AppTheme.errorColor,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _state == _ResetState.error ? 'Connection Error' : 'Invalid Link',
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
          _errorMessage.isNotEmpty
              ? _errorMessage
              : 'This reset link is invalid or has already been used.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF4B5563),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _goToLogin,
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }
}

enum _ResetState { form, success, expired, invalid, error }
