import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

/// Shown after successful registration.
/// Tells the user to check their email, and offers a "Resend" action.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String message;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.message,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _resending = false;
  String? _resendMessage;
  bool _resendSuccess = false;

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resendMessage = null;
    });

    try {
      await ApiService.instance.post('/api/auth/resend-verification', {
        'email': widget.email,
      });
      if (mounted) {
        setState(() {
          _resendSuccess = true;
          _resendMessage = 'A new verification email has been sent.';
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _resendSuccess = false;
          _resendMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resendSuccess = false;
          _resendMessage = 'Failed to resend. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4B5563),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 32),

              // Resend feedback banner
              if (_resendMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _resendSuccess
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _resendSuccess
                          ? AppTheme.successColor.withAlpha(77)
                          : AppTheme.errorColor.withAlpha(77),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _resendSuccess
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: _resendSuccess
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resendMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _resendSuccess
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Resend button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resending ? null : _resend,
                  icon: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(
                      _resending ? 'Sending…' : 'Resend Verification Email'),
                ),
              ),

              const SizedBox(height: 12),

              // Back to login
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  ),
                  child: const Text('Back to Sign In'),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'The link expires in 24 hours.\nOpen the link on your phone — it will launch the app directly.\nCheck your spam folder if you don\'t see the email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
