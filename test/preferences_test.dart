import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:reversia/engine/preferences.dart';

void main() {
  group('AppPreferences daily reminder settings', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to disabled at 19:00', () async {
      final prefs = await AppPreferences.init();

      expect(prefs.isDailyReminderEnabled, isFalse);
      expect(prefs.dailyReminderHour, 19);
      expect(prefs.dailyReminderMinute, 0);
    });

    test('setDailyReminderEnabled persists the flag', () async {
      final prefs = await AppPreferences.init();

      await prefs.setDailyReminderEnabled(true);

      expect(prefs.isDailyReminderEnabled, isTrue);
    });

    test('setDailyReminderTime persists both hour and minute', () async {
      final prefs = await AppPreferences.init();

      await prefs.setDailyReminderTime(8, 30);

      expect(prefs.dailyReminderHour, 8);
      expect(prefs.dailyReminderMinute, 30);
    });

    test('resetAll clears the daily reminder settings back to defaults', () async {
      final prefs = await AppPreferences.init();
      await prefs.setDailyReminderEnabled(true);
      await prefs.setDailyReminderTime(8, 30);

      await prefs.resetAll();

      expect(prefs.isDailyReminderEnabled, isFalse);
      expect(prefs.dailyReminderHour, 19);
      expect(prefs.dailyReminderMinute, 0);
    });
  });
}
