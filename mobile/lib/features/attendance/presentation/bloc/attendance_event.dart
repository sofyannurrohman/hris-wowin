import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class SubmitClockInEvent extends AttendanceEvent {
  final String photoPath;
  final List<double> embedding;

  const SubmitClockInEvent({required this.photoPath, required this.embedding});

  @override
  List<Object?> get props => [photoPath, embedding];
}

class SubmitClockOutEvent extends AttendanceEvent {
  final String photoPath;
  final List<double> embedding;

  const SubmitClockOutEvent({required this.photoPath, required this.embedding});

  @override
  List<Object?> get props => [photoPath, embedding];
}

class FetchHistoryRequested extends AttendanceEvent {
  final int page;
  final int limit;

  const FetchHistoryRequested({this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [page, limit];
}

class FetchHomeDataRequested extends AttendanceEvent {}
