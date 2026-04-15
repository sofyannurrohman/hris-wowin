import 'package:dio/dio.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/kpi/data/models/kpi_model.dart';
import 'package:hris_app/features/kpi/domain/repositories/kpi_repository.dart';

class KPIRepositoryImpl implements KPIRepository {
  final ApiClient apiClient;

  KPIRepositoryImpl({required this.apiClient});

  @override
  Future<List<KPIModel>> getKPIHistory() async {
    // Placeholder returning some dummy data for now
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const KPIModel(
        type: KPIType.sales,
        period: '2026-03',
        achievementPercentage: 110.5,
        finalScore: 88.0,
        status: KPIStatus.approved,
        approvedBy: 'Andi Kusuma (Sales Manager)',
        approvedAt: '2026-04-05',
        items: [
          KPIItem(label: 'Total Penjualan', score: 115, weight: '70%'),
          KPIItem(label: 'Visit Nasabah', score: 95, weight: '30%'),
        ],
      ),
      const KPIModel(
        type: KPIType.sales,
        period: '2026-02',
        achievementPercentage: 95.0,
        finalScore: 76.0,
        status: KPIStatus.approved,
        approvedBy: 'Andi Kusuma (Sales Manager)',
        approvedAt: '2026-03-04',
        items: [
          KPIItem(label: 'Total Penjualan', score: 90, weight: '70%'),
          KPIItem(label: 'Visit Nasabah', score: 105, weight: '30%'),
        ],
      ),
    ];
  }

  @override
  Future<KPIModel> getKPIByPeriod(String yearMonth) async {
    try {
      final response = await apiClient.client.get('employees/kpi/$yearMonth');
      if (response.statusCode == 200) {
        return KPIModel.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch KPI');
    } catch (e) {
      // Mock data for current month if API fails
      if (yearMonth == '2026-04') {
         return const KPIModel(
          type: KPIType.sales,
          period: '2026-04',
          achievementPercentage: 125.0,
          finalScore: 92.0,
          status: KPIStatus.draft,
          items: [
            KPIItem(label: 'Total Penjualan', score: 130, weight: '70%'),
            KPIItem(label: 'Visit Nasabah', score: 110, weight: '30%'),
          ],
        );
      }
      throw Exception('Gagal mengambil data KPI: $e');
    }
  }
}
