import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hris_app/core/network/api_client.dart';

class SalesApiService {
  final ApiClient apiClient;

  SalesApiService({required this.apiClient});

  // GET /api/v1/performance/my-performance
  Future<Map<String, dynamic>> getMyPerformance() async {
    try {
      final response = await apiClient.client.get('performance/my-performance');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Failed to load performance data: $e');
    }
  }

  // GET /api/v1/sales/transactions/pending
  Future<List<dynamic>> getPendingTransactions() async {
    try {
      final response = await apiClient.client.get('sales/transactions/pending');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } catch (e) {
      throw Exception('Failed to load pending transactions: $e');
    }
  }

  // GET /api/v1/sales/transactions/history
  Future<List<dynamic>> getHistoryTransactions() async {
    try {
      final response = await apiClient.client.get('sales/transactions/history');
      return (response.data['data'] as List<dynamic>?) ?? [];
    } catch (e) {
      throw Exception('Failed to load history transactions: $e');
    }
  }

  // POST /api/v1/sales/transactions
  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.client.post('sales/transactions', data: data);
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  // PATCH /api/v1/sales/transactions/:id/verify
  Future<void> verifyTransaction(String id, Map<String, dynamic> data) async {
    try {
      await apiClient.client.patch('sales/transactions/$id/verify', data: data);
    } catch (e) {
      throw Exception('Failed to verify transaction: $e');
    }
  }

  // GET /api/v1/sales/visit-plans
  Future<List<dynamic>> getVisitPlans({String? date}) async {
    try {
      final response = await apiClient.client.get('sales/visit-plans', queryParameters: date != null ? {'date': date} : null);
      return (response.data['data'] as List<dynamic>?) ?? [];
    } catch (e) {
      throw Exception('Failed to load visit plans: $e');
    }
  }
  // GET /api/v1/factory/products
  Future<List<dynamic>> getProducts() async {
    try {
      final response = await apiClient.client.get('factory/products');
      // Sometimes the data is wrapped in 'data' field, check the handler
      if (response.data is Map && response.data.containsKey('data')) {
        return (response.data['data'] as List<dynamic>?) ?? [];
      }
      return (response.data as List<dynamic>?) ?? [];
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}
