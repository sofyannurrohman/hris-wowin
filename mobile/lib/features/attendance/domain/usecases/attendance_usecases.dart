import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';
import 'package:hris_app/features/attendance/domain/entities/attendance.dart';
import 'package:hris_app/domain/repositories/attendance_repository.dart';

class CheckInUseCase {
  final AttendanceRepository repository;

  CheckInUseCase(this.repository);

  Future<Either<Failure, Attendance>> call(double lat, double lng, String? selfiePath) {
    return repository.checkIn(lat, lng, selfiePath);
  }
}

class CheckOutUseCase {
  final AttendanceRepository repository;

  CheckOutUseCase(this.repository);

  Future<Either<Failure, Attendance>> call(double lat, double lng, String? selfiePath) {
    return repository.checkOut(lat, lng, selfiePath);
  }
}

class GetAttendanceHistoryUseCase {
  final AttendanceRepository repository;

  GetAttendanceHistoryUseCase(this.repository);

  Future<Either<Failure, List<Attendance>>> call({int page = 1, int limit = 10}) {
    return repository.getHistory(page, limit);
  }
}
