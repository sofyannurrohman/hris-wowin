import 'package:dio/dio.dart';
import 'package:hris_app/core/network/api_client.dart';

class BannerOrderApiService {
  final ApiClient apiClient;

  BannerOrderApiService({required this.apiClient});

  // POST /api/v1/banner-orders
  Future<void> createBannerOrder(Map<String, dynamic> data) async {
    try {
      await apiClient.client.post('banner-orders', data: data);
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? 'Gagal membuat order spanduk');
      }
      throw Exception('Gagal membuat order spanduk: $e');
    }
  }
}
