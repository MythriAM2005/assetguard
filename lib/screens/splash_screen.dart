import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;
      // Try to restore session from stored JWT
      bool loggedIn = false;
      try {
        loggedIn = await AuthService.instance.tryAutoLogin();
      } catch (_) {
        loggedIn = false;
      }
      if (!mounted) return;

      // If logged in, request permissions BEFORE navigating
      if (loggedIn && mounted) {
        // Request permissions and WAIT for user response
        await PermissionService.instance.requestPermissionsAfterLogin(context);
      }

      // Navigate to appropriate screen AFTER permissions are handled
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, a, b) =>
                loggedIn ? const MainShell() : const LoginScreen(),
            transitionsBuilder: (_, anim, _, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1A73E8),
              Color(0xFF00BCD4),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(26),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withAlpha(77),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App name
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        const Text(
                          'AssetGuard AI',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Smart Asset Tracking & Recovery',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withAlpha(204),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 64),

                // Feature chips
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _featureChip(Icons.bluetooth_outlined, 'BLE Tracking'),
                      const SizedBox(width: 10),
                      _featureChip(Icons.psychology_outlined, 'AI Recovery'),
                      const SizedBox(width: 10),
                      _featureChip(Icons.group_outlined, 'Community'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1A73E8)],
          ),
        ),
        padding: const EdgeInsets.only(bottom: 32, top: 16),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Initializing...',
                style: TextStyle(
                  color: Colors.white.withAlpha(153),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withAlpha(230)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withAlpha(230),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
