import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _submitted = false; // show success state after send
  String _successMessage = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final msg = await AuthService.instance.forgotPassword(
        _emailCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _submitted = true;
          _successMessage = msg;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not reach the server. Check your connection and try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _submitted ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Reset your password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the email address associated with your account and we\'ll send you a reset link.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          CustomTextField(
            label: 'Email Address',
            hint: 'you@college.edu',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _send,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Send Reset Link'),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
            Icons.mark_email_read_outlined,
            size: 44,
            color: AppTheme.successColor,
          ),
        ),

        const SizedBox(height: 28),

        const Text(
          'Check Your Email',
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
          _successMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF4B5563),
            height: 1.6,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _emailCtrl.text.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Sign In'),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'The link expires in 15 minutes.\nOpen it on your phone — it will launch the app directly.\nCheck your spam folder if you don\'t see it.',
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
}
