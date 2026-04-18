import 'package:equatable/equatable.dart';

class Attendance extends Equatable {
  final String id;
  final String userId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String status;
  final String branchName;
  final String selfiePath;
  final int workDuration;

  const Attendance({
    required this.id,
    required this.userId,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.selfiePath = '',
    this.workDuration = 0,
    this.branchName = '',
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      checkIn: json['check_in'] != null ? DateTime.parse(json['check_in']).toLocal() : DateTime.now(),
      checkOut: json['check_out'] != null ? DateTime.parse(json['check_out']).toLocal() : null,
      status: json['status'] ?? 'UNKNOWN',
      selfiePath: json['selfie_url'] ?? '',
      workDuration: json['work_duration'] ?? 0,
      branchName: json['branch_name'] ?? json['BranchName'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, userId, checkIn, checkOut, status, selfiePath, workDuration, branchName];
}
