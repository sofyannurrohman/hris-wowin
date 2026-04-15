import 'package:equatable/equatable.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/features/attendance/data/repositories/attendance_repository.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();
  
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceSuccess extends AttendanceState {
  final String message;
  final Attendance attendance;
  const AttendanceSuccess({required this.message, required this.attendance});

  @override
  List<Object?> get props => [message, attendance];
}

class AttendanceFailure extends AttendanceState {
  final String message;
  const AttendanceFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AttendanceHistoryLoaded extends AttendanceState {
  final List<Attendance> history;

  const AttendanceHistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class AttendanceHistoryFailure extends AttendanceState {
  final String message;

  const AttendanceHistoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class HomeDataLoaded extends AttendanceState {
  final Map<String, dynamic> profile;
  final AttendanceStats stats;
  final List<Attendance> history;
  final int queueCount;
  final Map<String, dynamic>? statistics;

  const HomeDataLoaded({
    required this.profile, 
    required this.stats,
    required this.history,
    this.queueCount = 0,
    this.statistics,
  });

  @override
  List<Object?> get props => [profile, stats, history, queueCount, statistics];

  List<Attendance> get recentActivity => history;
}

class HomeDataFailure extends AttendanceState {
  final String message;
  const HomeDataFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FaceRegistrationLoading extends AttendanceState {}

class FaceRegistrationSuccess extends AttendanceState {}

class QueueCountLoaded extends AttendanceState {
  final int count;
  const QueueCountLoaded(this.count);

  @override
  List<Object?> get props => [count];
}

class SyncSuccess extends AttendanceState {
  final int successCount;
  final int failCount;
  const SyncSuccess(this.successCount, this.failCount);

  @override
  List<Object?> get props => [successCount, failCount];
}
