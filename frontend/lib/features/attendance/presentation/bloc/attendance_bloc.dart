import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:hris_app/features/auth/domain/repositories/auth_repository.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;
  final AuthRepository authRepository;

  AttendanceBloc({required this.repository, required this.authRepository}) : super(AttendanceInitial()) {
    
    on<FetchHomeDataRequested>((event, emit) async {
      emit(AttendanceLoading());
      try {
        final profileResult = await authRepository.getProfile();
        final stats = await repository.fetchStats();
        final history = await repository.fetchHistory(page: 1, limit: 5);
        
        profileResult.fold(
          (failure) => emit(HomeDataFailure(failure.message)),
          (profile) => emit(HomeDataLoaded(
            profile: profile, 
            stats: stats,
            history: history,
          )),
        );
      } catch (e) {
        final cleanMessage = e.toString().replaceAll('Exception: ', '');
        emit(HomeDataFailure(cleanMessage));
      }
    });
    on<SubmitClockInEvent>((event, emit) async {
      emit(AttendanceLoading()); 
      
      try {
        final message = await repository.clockIn(event.photoPath, event.embedding);
        emit(AttendanceSuccess(message));
      } catch (e) {
        final cleanMessage = e.toString().replaceAll('Exception: ', '');
        emit(AttendanceFailure(cleanMessage));
      }
    });

    on<SubmitClockOutEvent>((event, emit) async {
      emit(AttendanceLoading()); 
      
      try {
        final message = await repository.clockOut(event.photoPath, event.embedding);
        emit(AttendanceSuccess(message));
      } catch (e) {
        final cleanMessage = e.toString().replaceAll('Exception: ', '');
        emit(AttendanceFailure(cleanMessage));
      }
    });

    on<FetchHistoryRequested>((event, emit) async {
      emit(AttendanceLoading());
      try {
        final history = await repository.fetchHistory(page: event.page, limit: event.limit);
        emit(AttendanceHistoryLoaded(history));
      } catch (e) {
        final cleanMessage = e.toString().replaceAll('Exception: ', '');
        emit(AttendanceHistoryFailure(cleanMessage));
      }
    });

  }
}
