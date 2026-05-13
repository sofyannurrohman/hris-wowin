void main() {
  final date = DateTime(2026, 5, 12);
  final startTime = "08:00";
  final endTime = "17.00";

  print("Verifying Time Parsing and Reminders:");
  
  // Parse Start Time
  final normalizedStart = startTime.replaceAll('.', ':');
  final startParts = normalizedStart.split(':');
  final startDateTime = DateTime(date.year, date.month, date.day, int.parse(startParts[0]), int.parse(startParts[1]));
  
  final clockInAlertTime = startDateTime.subtract(Duration(minutes: 10));
  
  // Parse End Time
  final normalizedEnd = endTime.replaceAll('.', ':');
  final endParts = normalizedEnd.split(':');
  final endDateTime = DateTime(date.year, date.month, date.day, int.parse(endParts[0]), int.parse(endParts[1]));
  
  final clockOutAlertTime = endDateTime.subtract(Duration(minutes: 10));

  print("Date: ${date.toIso8601String()}");
  print("Start Time: $startTime -> DateTime: ${startDateTime.toIso8601String()}");
  print("Clock-In Alert (10m before): ${clockInAlertTime.toIso8601String()}");
  print("End Time: $endTime -> DateTime: ${endDateTime.toIso8601String()}");
  print("Clock-Out Alert (10m before): ${clockOutAlertTime.toIso8601String()}");
  
  if (clockInAlertTime.hour == 7 && clockInAlertTime.minute == 50) {
    print("SUCCESS: Clock-In alert at 07:50 for 08:00 start.");
  } else {
    print("FAILURE: Clock-In alert calculation incorrect.");
  }

  if (clockOutAlertTime.hour == 16 && clockOutAlertTime.minute == 50) {
    print("SUCCESS: Clock-Out alert at 16:50 for 17:00 end.");
  } else {
    print("FAILURE: Clock-Out alert calculation incorrect.");
  }
}
