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
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      userId: json['employee_id']?.toString() ?? json['EmployeeID']?.toString() ?? json['UserID']?.toString() ?? '',
      leaveTypeId: json['leave_type_id']?.toString() ?? json['LeaveTypeID']?.toString() ?? 
                  (json['leave_type'] != null ? json['leave_type']['id']?.toString() : 
                  (json['LeaveType'] != null ? json['LeaveType']['ID']?.toString() : null)),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']).toLocal() : 
                 (json['StartDate'] != null ? DateTime.parse(json['StartDate']).toLocal() : DateTime.now()),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']).toLocal() : 
               (json['EndDate'] != null ? DateTime.parse(json['EndDate']).toLocal() : DateTime.now()),
      reason: json['reason'] ?? json['Reason'] ?? '',
      status: json['status'] ?? json['Status'] ?? 'PENDING',
      leaveTypeName: json['leave_type_name'] ?? 
                    (json['leave_type'] != null ? json['leave_type']['name'] : 
                    (json['LeaveType'] != null ? json['LeaveType']['Name'] : null)),
      employeeName: json['employee_name'] ?? json['EmployeeName'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']).toLocal() : 
                 (json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']).toLocal() : null),
    );
  }

  @override
  List<Object?> get props => [id, userId, leaveTypeId, startDate, endDate, reason, status, employeeName, createdAt];
}
