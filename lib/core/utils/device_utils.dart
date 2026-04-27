import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/note_model.dart';

class DeviceUtils {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final canScheduleExact = await android?.canScheduleExactNotifications();
    if (canScheduleExact == false) {
      await android?.requestExactAlarmsPermission();
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> schedule(NoteModel note) async {
    if (kIsWeb ||
        note.reminderAt == null ||
        note.reminderAt!.isBefore(DateTime.now())) {
      return;
    }
    await cancel(note.id);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'smart_note_ai_reminders',
        '智能便签提醒',
        channelDescription: '便签闹钟和系统提醒',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    try {
      await _plugin.zonedSchedule(
        id: _intId(note.id),
        title: note.title,
        body: note.content,
        scheduledDate: tz.TZDateTime.from(note.reminderAt!, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: _intId(note.id),
        title: note.title,
        body: note.content,
        scheduledDate: tz.TZDateTime.from(note.reminderAt!, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    await _tryNativeAlarm(note);
  }

  Future<void> cancel(String noteId) {
    if (kIsWeb) return Future<void>.value();
    return _plugin.cancel(id: _intId(noteId));
  }

  Future<void> _tryNativeAlarm(NoteModel note) async {
    if (!DeviceUtils.isAndroid || note.reminderAt == null) return;
    final time = note.reminderAt!;
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': time.hour,
        'android.intent.extra.alarm.MINUTES': time.minute,
        'android.intent.extra.alarm.MESSAGE': 'AI 智能便签：${note.title}',
        'android.intent.extra.alarm.VIBRATE': true,
        'android.intent.extra.alarm.SKIP_UI': false,
      },
    );
    try {
      await intent.launch();
    } catch (_) {
      try {
        await const AndroidIntent(
          action: 'android.intent.action.SHOW_ALARMS',
        ).launch();
      } catch (_) {}
    }
  }

  int _intId(String id) =>
      id.codeUnits.fold(0, (sum, unit) => (sum + unit * 31) % 2147483647);
}
