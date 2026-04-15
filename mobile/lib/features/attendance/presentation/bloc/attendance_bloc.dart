import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_event.dart';
import 'package:hris_app/features/attendance/presentation/bloc/attendance_state.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
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
        final statsResult = await repository.fetchStats();
        final historyResult = await repository.getHistory(1, 10);
        final queueCount = await repository.getQueueCount();
        
        profileResult.fold(
          (failure) => emit(HomeDataFailure(failure.message)),
          (profile) {
            statsResult.fold(
              (failure) => emit(HomeDataFailure(failure.message)),
              (stats) {
                historyResult.fold(
                  (failure) => emit(HomeDataFailure(failure.message)),
                  (history) {
                    final mockStats = {
                      'PresentCount': stats.attendanceDays,
                      'LeaveCount': stats.leaveDays,
                      'AlphaCount': 0,
                    };
                    emit(HomeDataLoaded(
                      profile: profile, 
                      stats: stats,
                      history: history,
                      queueCount: queueCount,
                      statistics: mockStats,
                    ));
                  }
                );
              }
            );
          },
        );
      } catch (e) {
        emit(HomeDataFailure(e.toString()));
      }
    });

    on<ClockInRequested>((event, emit) async {
      emit(AttendanceLoading());
      final lat = event.latitude ?? 0.0;
      final lng = event.longitude ?? 0.0;
      
      if (event.isClockIn) {
        final result = await repository.checkIn(lat, lng, event.imagePath);
        result.fold(
          (failure) => emit(AttendanceFailure(failure.message)),
          (attendance) => emit(AttendanceSuccess(message: 'Absen Masuk Berhasil', attendance: attendance)),
        );
      } else {
        final result = await repository.checkOut(lat, lng, event.imagePath);
        result.fold(
          (failure) => emit(AttendanceFailure(failure.message)),
          (attendance) => emit(AttendanceSuccess(message: 'Absen Keluar Berhasil', attendance: attendance)),
        );
      }
    });

    on<RegisterFaceRequested>((event, emit) async {
      emit(FaceRegistrationLoading());
      final result = await authRepository.registerFace([], event.imagePath);
      result.fold(
        (failure) => emit(AttendanceFailure(failure.message)),
        (_) => emit(FaceRegistrationSuccess()),
      );
    });

    on<FetchHistoryRequested>((event, emit) async {
      emit(AttendanceLoading());
      final result = await repository.getHistory(event.page, event.limit);
      result.fold(
        (failure) => emit(AttendanceHistoryFailure(failure.message)),
        (history) => emit(AttendanceHistoryLoaded(history)),
      );
    });

    on<SaveOfflineAttendanceEvent>((event, emit) async {
      emit(AttendanceLoading());
      try {
        await repository.saveOffline(
          event.type,
          event.photoPath,
          event.latitude,
          event.longitude,
          [], 
        );
        final mockAttendance = Attendance(
          id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'local_user',
          checkIn: DateTime.now(),
          status: 'offline',
          selfiePath: event.photoPath,
        );
        emit(AttendanceSuccess(message: 'Absensi disimpan secara offline.', attendance: mockAttendance));
        add(GetQueueCountRequested());
      } catch (e) {
        emit(AttendanceFailure(e.toString()));
      }
    });

    on<SyncAttendanceQueueRequested>((event, emit) async {
      emit(AttendanceLoading());
      try {
        final result = await repository.syncQueue();
        emit(SyncSuccess(result['success'] ?? 0, result['fail'] ?? 0));
        add(FetchHomeDataRequested());
      } catch (e) {
        emit(AttendanceFailure(e.toString()));
      }
    });

    on<GetQueueCountRequested>((event, emit) async {
      final count = await repository.getQueueCount();
      emit(QueueCountLoaded(count));
    });
  }
}
