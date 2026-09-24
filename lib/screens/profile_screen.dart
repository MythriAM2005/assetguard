import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../services/asset_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Asset> _assets = [];
  bool _statsLoading = true;
  // null = no error; non-null = error message
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
      _statsError = null;
    });
    try {
      final assets = await AssetService.instance.getAssets();
      if (mounted) setState(() => _assets = assets);
    } on ApiException catch (e) {
      if (mounted) setState(() => _statsError = e.message);
    } catch (_) {
      if (mounted) setState(() => _statsError = 'Could not load statistics.');
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  // ── Computed counts ──────────────────────────────────────────────────────

  int get _total => _assets.length;
  int get _active => _assets.where((a) => a.status == 'ACTIVE').length;
  int get _lost => _assets.where((a) => a.status == 'LOST').length;
  int get _recovered => _assets.where((a) => a.status == 'RECOVERED').length;

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          children: [
            // ── Profile header ───────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white.withAlpha(77), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _initials(user?.fullName ?? 'U'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withAlpha(204),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Asset statistics ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStatsSection(),
            ),

            const SizedBox(height: 8),

            // ── Account section ──────────────────────────────────────────
            _sectionHeader('Account'),
            _listTile(
              icon: Icons.person_outline,
              label: 'Personal Information',
              subtitle: user?.fullName ?? '—',
              onTap: () => _showPersonalInfo(context),
            ),
            _listTile(
              icon: Icons.email_outlined,
              label: 'Email Address',
              subtitle: user?.email ?? '—',
              onTap: null,
            ),

            const Divider(height: 24, indent: 16, endIndent: 16),

            // ── Settings section ─────────────────────────────────────────
            _sectionHeader('Settings'),
            _listTile(
              icon: Icons.notifications_outlined,
              label: 'Notification Settings',
              onTap: () => _showNotificationSettings(context),
            ),
            _listTile(
              icon: Icons.lock_outline,
              label: 'Privacy & Security',
              onTap: () => _showPrivacySecurity(context),
            ),
            _listTile(
              icon: Icons.bluetooth_outlined,
              label: 'BLE & Tracking Settings',
              onTap: () => _showBleSettings(context),
            ),

            const Divider(height: 24, indent: 16, endIndent: 16),

            // ── About section ────────────────────────────────────────────
            _sectionHeader('About'),
            _listTile(
              icon: Icons.info_outline,
              label: 'About AssetGuard AI',
              onTap: () => _showAbout(context),
            ),
            _listTile(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () => _showHelp(context),
            ),
            _listTile(
              icon: Icons.policy_outlined,
              label: 'Privacy Policy',
              onTap: () => _showPrivacyPolicy(context),
            ),

            const Divider(height: 24, indent: 16, endIndent: 16),

            // ── Logout ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_outlined,
                      color: AppTheme.errorColor, size: 20),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                      color: AppTheme.errorColor, fontWeight: FontWeight.w600),
                ),
                onTap: () => _logout(context),
              ),
            ),

            const SizedBox(height: 8),
            const Center(
              child: Text(
                'AssetGuard AI  v1.0.0\nFinal Year Engineering Project',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD1D5DB),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Stats section widget ─────────────────────────────────────────────────

  Widget _buildStatsSection() {
    if (_statsLoading) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_statsError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 16, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _statsError!,
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ),
            TextButton(
              onPressed: _loadStats,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _statPill(
            key: const Key('stat_total'),
            label: 'Total',
            value: _total,
            icon: Icons.inventory_2_outlined,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          _statPill(
            key: const Key('stat_active'),
            label: 'Active',
            value: _active,
            icon: Icons.sensors_outlined,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 8),
          _statPill(
            key: const Key('stat_lost'),
            label: 'Lost',
            value: _lost,
            icon: Icons.gps_off_outlined,
            color: _lost > 0 ? AppTheme.errorColor : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          _statPill(
            key: const Key('stat_recovered'),
            label: 'Recovered',
            value: _recovered,
            icon: Icons.check_circle_outline,
            color: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _statPill({
    required Key key,
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EDF5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E)),
        ),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))
            : null,
        trailing: onTap != null
            ? const Icon(Icons.chevron_right,
                color: Color(0xFFD1D5DB), size: 20)
            : null,
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showPersonalInfo(BuildContext context) {
    final user = AuthService.instance.currentUser;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Personal Information'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              _InfoRow(
                label: 'Full Name',
                value: user?.fullName ?? 'Not set',
                icon: Icons.person,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Email Address',
                value: user?.email ?? 'Not set',
                icon: Icons.email,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'User ID',
                value: user?.id ?? 'Not available',
                icon: Icons.fingerprint,
              ),
              const SizedBox(height: 16),
              const Text(
                'To update your account information, please contact your system administrator.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySecurity(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Privacy & Security'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HelpSection(
                title: 'Account Security',
                items: const [
                  '• Your password is encrypted and never stored in plain text',
                  '• All API communication uses HTTPS encryption',
                  '• JWT tokens expire after 30 days',
                  '• Use "Forgot Password" to reset if compromised',
                ],
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: 'Data Privacy',
                items: const [
                  '• Only you can see your registered assets',
                  '• Community detections are anonymous',
                  '• Location data is only shared when sensing is active',
                  '• Delete your account to remove all data',
                ],
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: 'Permissions Used',
                items: const [
                  '• Bluetooth: Scan for BLE trackers',
                  '• Location: Wi-Fi fingerprinting & GPS',
                  '• Foreground Service: Background community sensing',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.policy_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Privacy Policy'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Collection & Usage',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'AssetGuard AI collects and processes the following data to provide asset tracking services:',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
              ),
              SizedBox(height: 12),
              Text(
                '• Account Information: Email address, name\n'
                '• Asset Data: Asset names, descriptions, tracker IDs\n'
                '• Location Data: BLE signal strength, Wi-Fi fingerprints, GPS coordinates when community sensing is active\n'
                '• Detection History: Timestamps and locations of asset detections',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                'Your Rights',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• You can delete your account and all associated data at any time\n'
                '• Community sensing is opt-in and can be disabled\n'
                '• Location data is only collected during active scanning\n'
                '• All data is encrypted in transit and at rest',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.6),
              ),
              SizedBox(height: 16),
              Text(
                'This is a college project for educational purposes. Contact your campus administrator for more information.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HelpSection(
                title: 'Getting Started',
                items: const [
                  '1. Register your BLE tracker by adding an asset',
                  '2. Mark an asset as LOST if you misplace it',
                  '3. Enable Community Sensing to help others',
                  '4. Check notifications when assets are found',
                ],
              ),
              const SizedBox(height: 16),
              _HelpSection(
                title: 'Troubleshooting',
                items: const [
                  '• Grant Bluetooth and Location permissions',
                  '• Ensure tracker ID matches your beacon (AG-XXX)',
                  '• Keep app running for community detection',
                  '• Check notification settings if not receiving alerts',
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'For technical support, contact your campus IT department or the AssetGuard development team.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Notification Settings'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Configuration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              _SettingRow(
                label: 'Asset Detected',
                value: 'Enabled',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 8),
              _SettingRow(
                label: 'Poll Interval',
                value: '30 seconds',
                icon: Icons.refresh_outlined,
              ),
              const SizedBox(height: 8),
              _SettingRow(
                label: 'Notification Sound',
                value: 'System Default',
                icon: Icons.volume_up_outlined,
              ),
              const SizedBox(height: 16),
              const Text(
                'Notifications are delivered when your lost assets are detected by the community. You can manage notification permissions in your device settings.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBleSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.bluetooth_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('BLE & Tracking'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Configuration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              _SettingRow(
                label: 'BLE Scanning',
                value: 'Enabled',
                icon: Icons.bluetooth_searching,
              ),
              const SizedBox(height: 8),
              _SettingRow(
                label: 'Community Sensing',
                value: 'Manual Control',
                icon: Icons.people_outline,
              ),
              const SizedBox(height: 8),
              _SettingRow(
                label: 'Scan Interval',
                value: '30 seconds',
                icon: Icons.schedule_outlined,
              ),
              const SizedBox(height: 8),
              _SettingRow(
                label: 'Tracker Filter',
                value: 'AG-* prefix',
                icon: Icons.filter_alt_outlined,
              ),
              const SizedBox(height: 16),
              const Text(
                'These settings are optimized for campus tracking and cannot be modified to ensure consistent community detection across all users.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('AssetGuard AI'),
          ],
        ),
        content: const Text(
          'AssetGuard AI is a smart campus asset tracking and recovery system.\n\n'
          'It uses BLE beacons, community sensing, and machine learning to help students locate and recover lost personal belongings.\n\n'
          'Version: 1.0.0\nBuilt with Flutter & Dart',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Helper widget for settings display
class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SettingRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

// Helper widget for info display in dialogs
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper widget for help sections
class _HelpSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _HelpSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        )),
      ],
    );
  }
}
