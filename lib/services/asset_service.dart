import '../models/asset_model.dart';
import 'api_service.dart';

/// All asset CRUD operations against the backend API.
class AssetService {
  AssetService._();
  static final AssetService instance = AssetService._();

  Future<List<Asset>> getAssets() async {
    final data = await ApiService.instance.get('/api/assets');
    final list = data['assets'] as List<dynamic>;
    return list.map((e) => Asset.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Asset> getAsset(String id) async {
    final data = await ApiService.instance.get('/api/assets/$id');
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<Asset> createAsset({
    required String name,
    required String category,
    required String description,
    required String trackerId,
  }) async {
    final data = await ApiService.instance.post('/api/assets', {
      'name': name,
      'category': category,
      'description': description,
      'trackerId': trackerId,
    });
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<Asset> updateAsset(String id, Map<String, dynamic> updates) async {
    final data = await ApiService.instance.put('/api/assets/$id', updates);
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<void> deleteAsset(String id) async {
    await ApiService.instance.delete('/api/assets/$id');
  }

  Future<Asset> markLost(String id) async {
    final data = await ApiService.instance.patch('/api/assets/$id/lost');
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<Asset> markRecovered(String id) async {
    final data = await ApiService.instance.patch('/api/assets/$id/recovered');
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }
}
