import 'package:equatable/equatable.dart';

class LeaveBalance extends Equatable {
  final String leaveTypeId;
  final String leaveTypeName;
  final bool isPaid;
  final bool requiresQuota;
  final int total;
  final int used;
  final int remaining;

  const LeaveBalance({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.isPaid,
    required this.requiresQuota,
    required this.total,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    final name = (json['leave_type_name'] ?? '').toString().toLowerCase();
    bool requiresQuota = json['requires_quota'] ?? true;
    
    // UI Robustness: Fallback if backend flag is missing or legacy
    if (name.contains('izin') || name.contains('sakit') || name.contains('musibah')) {
      requiresQuota = false;
    }

    return LeaveBalance(
      leaveTypeId: json['leave_type_id'] ?? '',
      leaveTypeName: json['leave_type_name'] ?? '',
      isPaid: json['is_paid'] ?? true,
      requiresQuota: requiresQuota,
      total: json['total'] ?? 0,
      used: json['used'] ?? 0,
      remaining: json['remaining'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [leaveTypeId, leaveTypeName, isPaid, requiresQuota, total, used, remaining];
}
