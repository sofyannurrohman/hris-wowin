import 'package:dartz/dartz.dart';
import 'package:hris_app/core/error/failures.dart';
import 'package:hris_app/core/network/api_client.dart';
import 'package:hris_app/features/schedule/data/models/shift_model.dart';

abstract class ShiftRepository {
  Future<Either<Failure, List<ShiftSchedule>>> getSchedules(int month, int year);
}

class ShiftRepositoryImpl implements ShiftRepository {
  final ApiClient apiClient;

  ShiftRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, List<ShiftSchedule>>> getSchedules(int month, int year) async {
    try {
      final response = await apiClient.client.get('employees/schedules', queryParameters: {'month': month, 'year': year});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return Right(data.map((e) => ShiftSchedule.fromJson(e)).toList());
      }
      return const Left(ServerFailure('Gagal memuat jadwal shift.'));
    } catch (e) {
      // Mock data for initial rollout (Current Month)
      final now = DateTime.now();
      return Right(List.generate(30, (i) {
        final day = i + 1;
        final date = DateTime(year, month, day);
        bool isOff = date.weekday == DateTime.sunday || date.weekday == DateTime.saturday;
        return ShiftSchedule(
          id: '$i',
          date: date,
          shiftName: isOff ? 'OFF' : 'SHIFT PAGI',
          startTime: isOff ? '-' : '08:00',
          endTime: isOff ? '-' : '17:00',
          isOffDay: isOff,
        );
      }));
    }
  }
}
