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
  const AttendanceSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AttendanceFailure extends AttendanceState {
  final String errorMessage;
  const AttendanceFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
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

  const HomeDataLoaded({
    required this.profile, 
    required this.stats,
    required this.history,
  });

  @override
  List<Object?> get props => [profile, stats, history];
}

class HomeDataFailure extends AttendanceState {
  final String message;
  const HomeDataFailure(this.message);

  @override
  List<Object?> get props => [message];
}
