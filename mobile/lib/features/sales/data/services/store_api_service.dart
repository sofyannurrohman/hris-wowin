import 'package:dio/dio.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';

class StoreApiService {
  final ApiClient apiClient;

  StoreApiService({required this.apiClient});

  // GET /api/v1/stores (backend will automatically filter by logged in user)
  Future<List<StoreModel>> getStores() async {
    try {
      final response = await apiClient.client.get('stores');
      final data = (response.data['data'] as List<dynamic>?) ?? [];
      return data.map((json) => StoreModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load stores: $e');
    }
  }

  // POST /api/v1/stores
  Future<StoreModel> createStore(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.client.post('stores', data: data);
      final json = response.data['data'];
      return StoreModel.fromJson(json);
    } catch (e) {
      throw Exception('Failed to create store: $e');
    }
  }

  // PUT /api/v1/stores/:id
  Future<StoreModel> updateStore(String id, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.client.put('stores/$id', data: data);
      final json = response.data['data'];
      return StoreModel(
        id: json['id'],
        name: json['name'] ?? '',
        ownerName: json['owner_name'] ?? '',
        address: json['address'] ?? '',
        isNew: json['is_new'] ?? false,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      throw Exception('Failed to update store: $e');
    }
  }

  // DELETE /api/v1/stores/:id
  Future<void> deleteStore(String id) async {
    try {
      await apiClient.client.delete('stores/$id');
    } catch (e) {
      throw Exception('Failed to delete store: $e');
    }
  }

  // GET /api/v1/stores/:id
  Future<StoreModel> getStoreByID(String id) async {
    try {
      final response = await apiClient.client.get('stores/$id');
      final json = response.data['data'];
      return StoreModel.fromJson(json);
    } catch (e) {
      throw Exception('Failed to get store details: $e');
    }
  }
}
