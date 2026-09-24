import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import 'email_verification_screen.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final message = await AuthService.instance.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      
      if (!mounted) return;

      // Check if user is already logged in (development mode with auto-verify)
      if (AuthService.instance.isLoggedIn) {
        // User was auto-verified and logged in - request permissions BEFORE navigating
        await PermissionService.instance.requestPermissionsAfterLogin(context);

        // Go directly to main app AFTER permissions are handled
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        }
      } else {
        // Normal flow - navigate to email verification screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                email: _emailCtrl.text.trim(),
                message: message,
              ),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed. Please try again.');
      debugPrint('[Register] Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                const Text(
                  'Join AssetGuard AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Register to start tracking your campus assets',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.errorColor.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorColor)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                CustomTextField(
                  label: 'Full Name',
                  hint: 'e.g. Alex Johnson',
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (v.trim().length < 2) { return 'Name is too short'; }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Email Address',
                  hint: 'you@college.edu',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!v.contains('@')) { return 'Enter a valid email'; }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: _passwordCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
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
                    onPressed: _loading ? null : _register,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Create Account'),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'By registering, you agree to our Terms of Service\nand Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.6),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
