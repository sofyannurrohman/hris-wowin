import 'package:equatable/equatable.dart';

enum AttendanceStatus { none, clockedIn, completed }

class Attendance {
  final DateTime checkIn;
  final DateTime? checkOut;
  Attendance({required this.checkIn, this.checkOut});
}

abstract class AttendanceState {
  final List<Attendance> history;
  AttendanceState(this.history);
}

class HomeDataLoaded extends AttendanceState {
  HomeDataLoaded(List<Attendance> history) : super(history);
}

extension AttendanceStateX on AttendanceState {
  AttendanceStatus get attendanceStatus {
    if (history.isEmpty) return AttendanceStatus.none;

    final last = history.first;
    final today = DateTime.now();
    final isToday = last.checkIn.year == today.year && 
                    last.checkIn.month == today.month && 
                    last.checkIn.day == today.day;

    if (!isToday) return AttendanceStatus.none;

    return last.checkOut == null ? AttendanceStatus.clockedIn : AttendanceStatus.completed;
  }
}

void main() {
  print("Verifying Multiple Session Status Logic:");
  
  final now = DateTime.now();

  // Scenario 1: No history today
  final state1 = HomeDataLoaded([]);
  print("Scenario 1 (No history): ${state1.attendanceStatus} (Expected: none)");

  // Scenario 2: Clocked in today
  final state2 = HomeDataLoaded([
    Attendance(checkIn: now.subtract(Duration(hours: 1)))
  ]);
  print("Scenario 2 (Clocked in): ${state2.attendanceStatus} (Expected: clockedIn)");

  // Scenario 3: Clocked out today (one session)
  final state3 = HomeDataLoaded([
    Attendance(checkIn: now.subtract(Duration(hours: 4)), checkOut: now.subtract(Duration(hours: 1)))
  ]);
  print("Scenario 3 (Clocked out): ${state3.attendanceStatus} (Expected: completed)");

  // Scenario 4: Re-clocked in today (two sessions)
  final state4 = HomeDataLoaded([
    Attendance(checkIn: now.subtract(Duration(minutes: 30))),
    Attendance(checkIn: now.subtract(Duration(hours: 4)), checkOut: now.subtract(Duration(hours: 1)))
  ]);
  print("Scenario 4 (Re-clocked in): ${state4.attendanceStatus} (Expected: clockedIn)");

  // Scenario 5: Re-clocked out today (two sessions)
  final state5 = HomeDataLoaded([
    Attendance(checkIn: now.subtract(Duration(hours: 2)), checkOut: now.subtract(Duration(hours: 1))),
    Attendance(checkIn: now.subtract(Duration(hours: 6)), checkOut: now.subtract(Duration(hours: 4)))
  ]);
  print("Scenario 5 (Re-clocked out): ${state5.attendanceStatus} (Expected: completed)");
}
