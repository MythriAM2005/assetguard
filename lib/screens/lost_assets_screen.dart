import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../services/asset_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/asset_card.dart';
import 'asset_details_screen.dart';

class LostAssetsScreen extends StatefulWidget {
  const LostAssetsScreen({super.key});

  @override
  State<LostAssetsScreen> createState() => _LostAssetsScreenState();
}

class _LostAssetsScreenState extends State<LostAssetsScreen> {
  List<Asset> _lostAssets = [];
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
      final all = await AssetService.instance.getAssets();
      if (mounted) {
        setState(() =>
            _lostAssets = all.where((a) => a.status == 'LOST').toList());
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load lost assets.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost Assets'),
        actions: [
          if (_lostAssets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_lostAssets.length} Lost',
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAssets,
              child: _error != null
                  ? _errorState()
                  : _lostAssets.isEmpty
                      ? _emptyState()
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Alert banner
                            Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.errorColor.withAlpha(77)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: AppTheme.errorColor, size: 20),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Community Tracking Active',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.errorColor,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Other users on campus will help detect your lost assets via BLE scanning. You'll be notified when they are found.",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.errorColor,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            ..._lostAssets.map((a) => _lostAssetCard(a)),
                          ],
                        ),
            ),
    );
  }

  Widget _lostAssetCard(Asset asset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withAlpha(51)),
      ),
      child: Column(
        children: [
          AssetCard(
            asset: asset,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AssetDetailsScreen(asset: asset)),
              );
              _loadAssets();
            },
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8F8),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_outlined,
                    size: 14, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Last seen: ${asset.lastDetectedTime}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AssetDetailsScreen(asset: asset)),
                    );
                    _loadAssets();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View Details →',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 56, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAssets,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 52,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Assets Accounted For',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            const Text(
              'None of your registered assets are currently reported as lost.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}
