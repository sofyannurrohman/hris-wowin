import 'package:equatable/equatable.dart';

class LeaveBalance extends Equatable {
  final String leaveTypeId;
  final String leaveTypeName;
  final bool isPaid;
  final int total;
  final int used;
  final int remaining;

  const LeaveBalance({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.isPaid,
    required this.total,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      leaveTypeId: json['leave_type_id'] ?? '',
      leaveTypeName: json['leave_type_name'] ?? '',
      isPaid: json['is_paid'] ?? true, // Default to true if not present
      total: json['total'] ?? 0,
      used: json['used'] ?? 0,
      remaining: json['remaining'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [leaveTypeId, leaveTypeName, isPaid, total, used, remaining];
}
