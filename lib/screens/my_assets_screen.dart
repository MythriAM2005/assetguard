import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import '../services/asset_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/asset_card.dart';
import 'add_asset_screen.dart';
import 'asset_details_screen.dart';

class MyAssetsScreen extends StatefulWidget {
  const MyAssetsScreen({super.key});

  @override
  State<MyAssetsScreen> createState() => _MyAssetsScreenState();
}

class _MyAssetsScreenState extends State<MyAssetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Asset> _assets = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAssets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final assets = await AssetService.instance.getAssets();
      if (mounted) setState(() => _assets = assets);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load assets.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Asset> get _filtered {
    final q = _search.toLowerCase();
    List<Asset> list;
    switch (_tabController.index) {
      case 1:
        list = _assets.where((a) => a.status == 'ACTIVE').toList();
        break;
      case 2:
        list = _assets.where((a) => a.status == 'LOST').toList();
        break;
      default:
        list = _assets;
    }
    if (q.isEmpty) return list;
    return list
        .where((a) =>
            a.name.toLowerCase().contains(q) ||
            a.category.toLowerCase().contains(q) ||
            a.trackerId.toLowerCase().contains(q))
        .toList();
  }

  int get _activeCount => _assets.where((a) => a.status == 'ACTIVE').length;
  int get _lostCount => _assets.where((a) => a.status == 'LOST').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Asset',
            onPressed: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AddAssetScreen()),
              );
              if (added == true) _loadAssets();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search assets…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _search = ''),
                          )
                        : null,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'All (${_assets.length})'),
                  Tab(text: 'Active ($_activeCount)'),
                  Tab(text: 'Lost ($_lostCount)'),
                ],
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: const Color(0xFF9CA3AF),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: const Color(0xFFE8EDF5),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : _filtered.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAssets,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => AssetCard(
                          asset: _filtered[i],
                          onTap: () async {
                            await Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                  builder: (_) => AssetDetailsScreen(
                                      asset: _filtered[i])),
                            );
                            _loadAssets();
                          },
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddAssetScreen()),
          );
          if (added == true) _loadAssets();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Asset'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
    final isSearch = _search.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch
                  ? Icons.search_off_outlined
                  : Icons.inventory_2_outlined,
              size: 64,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'No results for "$_search"' : 'No assets here',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try a different search term.'
                  : 'Tap the + button to add your first asset.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
