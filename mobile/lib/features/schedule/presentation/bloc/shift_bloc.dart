import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/schedule/data/models/shift_model.dart';
import 'package:hris_app/features/schedule/data/repositories/shift_repository.dart';
import 'package:hris_app/core/services/notification_service.dart';

// Events
abstract class ShiftEvent extends Equatable {
  const ShiftEvent();
  @override
  List<Object?> get props => [];
}

class FetchSchedulesRequested extends ShiftEvent {
  final int month;
  final int year;
  const FetchSchedulesRequested({required this.month, required this.year});
  @override
  List<Object?> get props => [month, year];
}

// States
abstract class ShiftState extends Equatable {
  const ShiftState();
  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {}
class ShiftLoading extends ShiftState {}
class ShiftLoaded extends ShiftState {
  final List<ShiftSchedule> schedules;
  const ShiftLoaded(this.schedules);
  @override
  List<Object?> get props => [schedules];
}
class ShiftFailure extends ShiftState {
  final String message;
  const ShiftFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftRepository repository;
  final NotificationService notificationService;

  ShiftBloc({required this.repository, required this.notificationService}) : super(ShiftInitial()) {
    on<FetchSchedulesRequested>((event, emit) async {
      emit(ShiftLoading());
      final result = await repository.getSchedules(event.month, event.year);
      result.fold(
        (failure) => emit(ShiftFailure(failure.message)),
        (lists) {
          notificationService.scheduleShiftNotifications(lists);
          emit(ShiftLoaded(lists));
        },
      );
    });
  }
}
