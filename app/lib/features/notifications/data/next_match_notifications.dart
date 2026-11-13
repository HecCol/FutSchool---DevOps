import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../admin/domain/admin_models.dart';

class NextMatchNotifications {
  NextMatchNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _initializing = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized || _initializing) return;
    _initializing = true;
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      _initialized = true;
    } catch (_) {
      // A notification integration failure must not prevent login or gameplay.
    } finally {
      _initializing = false;
    }
  }

  static int _notificationId(String matchId) {
    var hash = 0x811c9dc5;
    for (final unit in matchId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static Future<bool> hasReminder(String matchId) async {
    await initialize();
    if (!_initialized) return false;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.any((item) => item.id == _notificationId(matchId));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> scheduleForMatch({
    required AdminMatch match,
    required String homeTeam,
    required String awayTeam,
  }) async {
    await initialize();
    if (!_initialized || match.status != AdminMatchStatus.scheduled)
      return false;

    final matchTime = match.startsAt.toLocal();
    final now = DateTime.now();
    if (!matchTime.isAfter(now.add(const Duration(minutes: 5)))) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final permission = await android.requestNotificationsPermission();
      if (permission == false) return false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final permission = await ios.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      if (permission == false) return false;
    }

    final reminderAt = matchTime.subtract(const Duration(hours: 1));
    final scheduleAt = reminderAt.isAfter(now)
        ? reminderAt
        : matchTime.subtract(const Duration(minutes: 5));
    if (!scheduleAt.isAfter(now)) return false;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'futschool_match_reminders',
        'Recordatorios de partidos',
        channelDescription: 'Avisos locales antes de los partidos programados.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      _notificationId(match.id),
      'Próximo partido',
      '$homeTeam vs. $awayTeam comienza en ${reminderAt.isAfter(now) ? 'una hora' : 'unos minutos'}.',
      tz.TZDateTime.from(scheduleAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: match.id,
    );
    return true;
  }

  static Future<void> cancel(String matchId) async {
    await initialize();
    if (!_initialized) return;
    await _plugin.cancel(_notificationId(matchId));
  }
}
