import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:hris_app/features/schedule/data/models/shift_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification click if needed
      },
    );
  }

  Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleShiftNotifications(List<ShiftSchedule> schedules) async {
    // Cancel all existing shift notifications to avoid duplicates
    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();

    for (var schedule in schedules) {
      if (schedule.isOffDay || schedule.startTime == '-' || schedule.endTime == '-') continue;

      try {
        // Schedule Clock-In Alert (15 min before)
        final startDateTime = _parseShiftTime(schedule.date, schedule.startTime);
        final clockInAlertTime = startDateTime.subtract(const Duration(minutes: 15));

        if (clockInAlertTime.isAfter(now)) {
          await _scheduleNotification(
            id: schedule.date.day * 100 + 1, // Unique ID per day for clock-in
            title: 'Persiapan Absensi Masuk',
            body: 'Selamat pagi! 15 menit lagi waktu absen masuk Anda (${schedule.startTime}). Jangan lupa melakukan presensi.',
            scheduledDate: clockInAlertTime,
          );
        }

        // Schedule Clock-Out Alert (exactly at endTime)
        final endDateTime = _parseShiftTime(schedule.date, schedule.endTime);
        if (endDateTime.isAfter(now)) {
          await _scheduleNotification(
            id: schedule.date.day * 100 + 2, // Unique ID per day for clock-out
            title: 'Waktu Kerja Berakhir',
            body: 'Waktu kerja Anda telah berakhir (${schedule.endTime}). Terima kasih atas dedikasi Anda hari ini. Jangan lupa absen keluar!',
            scheduledDate: endDateTime,
          );
        }
      } catch (e) {
        // Silently skip if date parsing fails for some reason
      }
    }
  }

  DateTime _parseShiftTime(DateTime date, String timeStr) {
    // timeStr expected as "HH:mm" or "HH.mm"
    final normalizedTime = timeStr.replaceAll('.', ':');
    final timeParts = normalizedTime.split(':');
    if (timeParts.length != 2) throw Exception('Invalid time format');
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'shift_alerts',
          'Shift Alerts',
          channelDescription: 'Notifications for shift clock-in and clock-out',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }
}
