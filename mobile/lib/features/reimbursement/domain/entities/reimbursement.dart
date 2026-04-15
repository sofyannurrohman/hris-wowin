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
      id: json['ID'] ?? '',
      employeeId: json['EmployeeID'] ?? '',
      title: json['Title'] ?? '',
      description: json['Description'],
      amount: (json['Amount'] as num?)?.toDouble() ?? 0.0,
      attachmentUrl: json['AttachmentURL'],
      status: json['Status'] ?? 'PENDING',
      rejectedReason: json['RejectedReason'],
      createdAt: DateTime.parse(json['CreatedAt'] ?? DateTime.now().toIso8601String()),
      employeeName: json['EmployeeName'],
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
