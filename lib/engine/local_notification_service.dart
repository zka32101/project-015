import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules (and cancels) a daily local reminder notification -- entirely
/// on-device, no server or Firebase project involved. This is deliberately
/// simple: one fixed time, no awareness of whether today's daily challenge
/// is already done, since flutter_local_notifications schedules ahead of
/// time and can't consult live app state when the notification fires.
///
/// Uses AndroidScheduleMode.inexactAllowWhileIdle rather than an exact
/// alarm, so it doesn't need Android 12+'s special "exact alarm" permission
/// -- the notification may fire a few minutes late, which is an acceptable
/// trade for a reminder like this.
class LocalNotificationService {
  static const int _dailyReminderId = 1001;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = 'デイリーリマインダー';

  LocalNotificationService._();
  static final LocalNotificationService _instance = LocalNotificationService._();
  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // Falls back to whatever the timezone package defaults to (UTC) --
      // the reminder will still fire, just not necessarily at the exact
      // local time the user picked.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  /// Requests the OS-level notification permission (Android 13+, iOS).
  /// Returns true if granted (or already granted on platforms that don't
  /// ask, like older Android).
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  /// Schedules a notification that repeats daily at [hour]:[minute] (local
  /// time), replacing any previously scheduled one.
  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    await _ensureInitialized();

    final next = _nextInstanceOf(hour, minute);
    await _plugin.zonedSchedule(
      _dailyReminderId,
      'リバーシア',
      '今日のデイリーチャレンジはまだです。挑戦しましょう！',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(_dailyReminderId);
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
