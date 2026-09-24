import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/verify_email_callback_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/community_sensing_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the foreground task options once at startup.
  // Does NOT start the service — only registers the notification channel.
  CommunitySensingService.initForegroundTask();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AssetGuardApp());
}

class AssetGuardApp extends StatefulWidget {
  const AssetGuardApp({super.key});

  @override
  State<AssetGuardApp> createState() => _AssetGuardAppState();
}

class _AssetGuardAppState extends State<AssetGuardApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links that open the app from cold start
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle links while the app is already running
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'assetguard') return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    if (uri.host == 'verify-email') {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => VerifyEmailCallbackScreen(token: token),
        ),
        (_) => false,
      );
    } else if (uri.host == 'reset-password') {
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssetGuard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      home: const SplashScreen(),
    );
  }
}
