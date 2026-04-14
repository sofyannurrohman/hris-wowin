import 'package:equatable/equatable.dart';

class Attendance extends Equatable {
  final String id;
  final String userId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String status;
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
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['ID'] ?? '',
      userId: json['UserID'] ?? '',
      checkIn: json['CheckIn'] != null ? DateTime.parse(json['CheckIn']).toLocal() : DateTime.now(),
      checkOut: json['CheckOut'] != null ? DateTime.parse(json['CheckOut']).toLocal() : null,
      status: json['Status'] ?? 'UNKNOWN',
      selfiePath: json['SelfieURL'] ?? '',
      workDuration: json['WorkDuration'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, userId, checkIn, checkOut, status, selfiePath, workDuration];
}
