import 'package:equatable/equatable.dart';

abstract class OvertimeEvent extends Equatable {
  const OvertimeEvent();

  @override
  List<Object?> get props => [];
}

class SubmitOvertimeRequested extends OvertimeEvent {
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String type;
  final String reason;

  const SubmitOvertimeRequested({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.type,
    required this.reason,
  });

  @override
  List<Object?> get props => [date, startTime, endTime, durationMinutes, type, reason];
}

class UpdateOvertimeRequested extends OvertimeEvent {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String type;
  final String reason;

  const UpdateOvertimeRequested({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.type,
    required this.reason,
  });

  @override
  List<Object?> get props => [id, date, startTime, endTime, durationMinutes, type, reason];
}

class DeleteOvertimeRequested extends OvertimeEvent {
  final String id;

  const DeleteOvertimeRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class FetchMyOvertimesRequested extends OvertimeEvent {}
