import 'package:equatable/equatable.dart';

class Leave extends Equatable {
  final String id;
  final String userId;
  final String? leaveTypeId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final String? leaveTypeName;
  final String? employeeName;
  final DateTime? createdAt;

  const Leave({
    required this.id,
    required this.userId,
    this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.leaveTypeName,
    this.employeeName,
    this.createdAt,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['ID'] ?? '',
      userId: json['EmployeeID'] ?? json['UserID'] ?? '',
      leaveTypeId: json['LeaveTypeID'] ?? (json['LeaveType'] != null ? json['LeaveType']['ID'] : null),
      startDate: json['StartDate'] != null ? DateTime.parse(json['StartDate']).toLocal() : DateTime.now(),
      endDate: json['EndDate'] != null ? DateTime.parse(json['EndDate']).toLocal() : DateTime.now(),
      reason: json['Reason'] ?? '',
      status: json['Status'] ?? 'PENDING',
      leaveTypeName: json['LeaveTypeName'] ?? (json['LeaveType'] != null ? json['LeaveType']['Name'] : null),
      employeeName: json['EmployeeName'],
      createdAt: json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']).toLocal() : null,
    );
  }

  @override
  List<Object?> get props => [id, userId, leaveTypeId, startDate, endDate, reason, status, employeeName, createdAt];
}
