import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit.dart';

/// Wraps [FlutterLocalNotificationsPlugin] so the rest of the app can schedule
/// real, recurring habit reminders without touching platform channels.
///
/// Reminders are weekly-recurring: one notification per scheduled weekday, at
/// the habit's chosen time. They survive reboots (see the boot receiver in the
/// Android manifest) and require no network.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _tzReady = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'habit_reminders',
    'Habit reminders',
    channelDescription: 'Nudges to keep your orbs rolling',
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.reminder,
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _androidDetails);

  Future<void> init() async {
    if (_ready) return;
    await _ensureTimezone();

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: android);

    try {
      await _plugin.initialize(settings: settings);
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> _ensureTimezone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final String name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _tzReady = true;
  }

  /// Asks the OS for permission to post notifications (Android 13+) and to
  /// schedule exact alarms. Safe to call repeatedly. Returns whether granted.
  Future<bool> requestPermissions() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    final bool? granted = await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
    return granted ?? true;
  }

  Future<bool> hasPermission() async {
    await init();
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return await android.areNotificationsEnabled() ?? false;
  }

  /// Notification ids are derived deterministically so a habit's reminders can
  /// be cancelled without storing the ids. weekday is 1..7.
  int _idFor(String habitId, int weekday) =>
      (habitId.hashCode & 0x0FFFFFF) * 8 + weekday;

  Future<void> cancelForHabit(Habit habit) async {
    await init();
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(id: _idFor(habit.id, weekday));
    }
  }

  Future<void> scheduleForHabit(Habit habit) async {
    await init();
    await cancelForHabit(habit);

    if (habit.archived || habit.reminderMinutes == null) return;

    final int minutes = habit.reminderMinutes!;
    final int hour = minutes ~/ 60;
    final int minute = minutes % 60;

    for (final int weekday in habit.scheduledWeekdays) {
      final tz.TZDateTime when = _nextInstanceOf(weekday, hour, minute);
      try {
        await _plugin.zonedSchedule(
          id: _idFor(habit.id, weekday),
          title: habit.title,
          body: _body(habit),
          scheduledDate: when,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        debugPrint('scheduleForHabit failed (${habit.title}): $e');
      }
    }
  }

  String _body(Habit habit) {
    if (habit.kind == HabitKind.quit) {
      return 'Stay strong — keep the streak alive.';
    }
    if (habit.dailyTarget > 1) {
      return 'Time to roll: ${habit.dailyTarget} ${habit.unit} to go.';
    }
    return 'Your orb is waiting on the trail.';
  }

  tz.TZDateTime _nextInstanceOf(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Rebuilds the full reminder schedule from scratch — used on launch and
  /// after bulk edits so the OS state always matches the habit list.
  Future<void> rescheduleAll(List<Habit> habits) async {
    await init();
    await _plugin.cancelAll();
    for (final Habit h in habits) {
      await scheduleForHabit(h);
    }
  }
}
