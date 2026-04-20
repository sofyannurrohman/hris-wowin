import 'package:equatable/equatable.dart';

class Reimbursement extends Equatable {
  final String id;
  final String employeeId;
  final String title;
  final String? description;
  final double amount;
  final String? attachmentUrl;
  final String status;
  final String? rejectedReason;
  final DateTime createdAt;
  final String? employeeName;

  const Reimbursement({
    required this.id,
    required this.employeeId,
    required this.title,
    this.description,
    required this.amount,
    this.attachmentUrl,
    required this.status,
    this.rejectedReason,
    required this.createdAt,
    this.employeeName,
  });

  factory Reimbursement.fromJson(Map<String, dynamic> json) {
    return Reimbursement(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? json['EmployeeID']?.toString() ?? '',
      title: json['title'] ?? json['Title'] ?? '',
      description: json['description'] ?? json['Description'],
      amount: (json['amount'] as num?)?.toDouble() ?? (json['Amount'] as num?)?.toDouble() ?? 0.0,
      attachmentUrl: json['attachment_url'] ?? json['AttachmentURL'],
      status: json['status'] ?? json['Status'] ?? 'PENDING',
      rejectedReason: json['rejected_reason'] ?? json['RejectedReason'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']).toLocal() : 
                 (json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']).toLocal() : DateTime.now()),
      employeeName: json['employee_name'] ?? json['EmployeeName'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        title,
        description,
        amount,
        attachmentUrl,
        status,
        rejectedReason,
        createdAt,
        employeeName,
      ];
}
