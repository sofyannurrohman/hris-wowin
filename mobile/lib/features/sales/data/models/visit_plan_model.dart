import 'package:hris_app/features/sales/data/models/store_model.dart';

class VisitPlanModel {
  final String storeId;
  final String storeName;
  final String address;
  final String status; // PLANNED, COMPLETED, EXTRA
  final bool isExtra;
  final String? visitId;

  VisitPlanModel({
    required this.storeId,
    required this.storeName,
    required this.address,
    required this.status,
    required this.isExtra,
    this.visitId,
  });

  factory VisitPlanModel.fromJson(Map<String, dynamic> json) {
    return VisitPlanModel(
      storeId: json['store_id'] ?? '',
      storeName: json['store_name'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'PLANNED',
      isExtra: json['is_extra'] ?? false,
      visitId: json['visit_id'],
    );
  }
}
