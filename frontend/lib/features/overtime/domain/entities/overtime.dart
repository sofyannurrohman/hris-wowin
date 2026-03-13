import 'package:equatable/equatable.dart';

class Overtime extends Equatable {
  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String reason;
  final String status;
  final String? rejectReason;

  const Overtime({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.reason,
    required this.status,
    this.rejectReason,
  });

  factory Overtime.fromJson(Map<String, dynamic> json) {
    return Overtime(
      id: json['ID'] ?? '',
      employeeId: json['EmployeeID'] ?? '',
      date: DateTime.parse(json['Date']),
      startTime: DateTime.parse(json['StartTime']),
      endTime: DateTime.parse(json['EndTime']),
      durationMinutes: json['DurationMinutes'] ?? 0,
      reason: json['Reason'] ?? '',
      status: json['Status'] ?? 'pending',
      rejectReason: json['RejectReason'],
    );
  }

  @override
  List<Object?> get props => [id, employeeId, date, startTime, endTime, durationMinutes, reason, status, rejectReason];
}
