import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../models/dashboard_stats_model.dart';
import '../services/asset_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/dashboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/asset_card.dart';
import 'add_asset_screen.dart';
import 'asset_details_screen.dart';
import 'main_shell.dart';
import 'nearby_devices_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Asset> _assets = [];
  DashboardStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Load both assets and dashboard stats in parallel
      final results = await Future.wait([
        AssetService.instance.getAssets(),
        DashboardService.instance.getStats(),
      ]);
      
      if (mounted) {
        setState(() {
          _assets = results[0] as List<Asset>;
          _stats = results[1] as DashboardStats;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load dashboard data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Asset> get _lostAssets =>
      _assets.where((a) => a.status == 'LOST').toList();

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final firstName = user?.fullName.split(' ').first ?? 'Student';

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: RefreshIndicator(
        onRefresh: _loadAssets,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              snap: true,
              backgroundColor: AppTheme.surfaceColor,
              scrolledUnderElevation: 1,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hello, $firstName 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Here's your asset overview",
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFE8EDF5)),
                            ),
                            child: StreamBuilder<int>(
                              stream: NotificationService.instance.unreadCountStream,
                              initialData: NotificationService.instance.unreadCount,
                              builder: (context, snapshot) {
                                return IconButton(
                                  icon: const Icon(
                                      Icons.notifications_outlined,
                                      size: 22),
                                  color: const Color(0xFF374151),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          StreamBuilder<int>(
                            stream: NotificationService.instance.unreadCountStream,
                            initialData: NotificationService.instance.unreadCount,
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.data ?? 0;
                              if (unreadCount == 0) return const SizedBox.shrink();
                              
                              return Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  if (_error != null) ...[
                    _errorBanner(_error!),
                    const SizedBox(height: 16),
                  ],

                  if (_lostAssets.isNotEmpty && _error == null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.errorColor.withAlpha(77)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_outlined,
                              color: AppTheme.errorColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_lostAssets.length} asset${_lostAssets.length > 1 ? 's' : ''} reported lost.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stats
                  const Text('Overview',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ))
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Total Assets',
                            value: (_stats?.totalAssets ?? 0).toString(),
                            icon: Icons.inventory_2_outlined,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Tracking',
                            value: (_stats?.activeTrackingAssets ?? 0).toString(),
                            icon: Icons.location_searching_outlined,
                            color: (_stats?.activeTrackingAssets ?? 0) > 0
                                ? AppTheme.successColor
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            label: 'Lost',
                            value: (_stats?.lostAssets ?? 0).toString(),
                            icon: Icons.gps_off_outlined,
                            color: (_stats?.lostAssets ?? 0) > 0
                                ? AppTheme.errorColor
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick actions
                    const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _quickAction(
                          icon: Icons.add_circle_outline,
                          label: 'Add Asset',
                          color: AppTheme.primaryColor,
                          onTap: () async {
                            final added = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddAssetScreen()),
                            );
                            if (added == true) _loadAssets();
                          },
                        ),
                        _quickAction(
                          icon: Icons.inventory_2_outlined,
                          label: 'My Assets',
                          color: AppTheme.accentColor,
                          onTap: () =>
                              MainShell.of(context)
                                  ?.switchTab(MainShellTabs.myAssets),
                        ),
                        _quickAction(
                          icon: Icons.report_problem_outlined,
                          label: 'Report Lost',
                          color: AppTheme.errorColor,
                          onTap: () =>
                              MainShell.of(context)
                                  ?.switchTab(MainShellTabs.lost),
                        ),
                        _quickAction(
                          icon: Icons.bluetooth_searching_outlined,
                          label: 'Nearby',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NearbyDevicesScreen()),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent assets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Assets',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                        TextButton(
                          onPressed: _loadAssets,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('See All',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_assets.isEmpty)
                      _emptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'No assets yet',
                        subtitle:
                            'Tap "Add Asset" to register your first asset.',
                      )
                    else
                      ..._assets.take(3).map(
                            (a) => AssetCard(
                              asset: a,
                              onTap: () async {
                                final recovered = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          AssetDetailsScreen(asset: a)),
                                );
                                // Reload if asset was recovered
                                if (recovered == true) {
                                  _loadAssets();
                                }
                              },
                            ),
                          ),

                    const SizedBox(height: 24),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined,
              color: AppTheme.warningColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.warningColor)),
          ),
          TextButton(
            onPressed: _loadAssets,
            child: const Text('Retry',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.warningColor)),
          ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}
