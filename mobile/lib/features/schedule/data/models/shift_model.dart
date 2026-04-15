import 'package:equatable/equatable.dart';

class ShiftSchedule extends Equatable {
  final String id;
  final DateTime date;
  final String shiftName;
  final String startTime;
  final String endTime;
  final bool isOffDay;

  const ShiftSchedule({
    required this.id,
    required this.date,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    this.isOffDay = false,
  });

  @override
  List<Object?> get props => [id, date, shiftName, startTime, endTime, isOffDay];

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) {
    return ShiftSchedule(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      shiftName: json['shift_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      isOffDay: json['is_off_day'] ?? false,
    );
  }
}
