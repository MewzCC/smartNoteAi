import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/note_model.dart';
import '../../shared/enums/reminder_repeat.dart';

class DeviceUtils {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    await _initTimezone();
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
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'smart_note_ai_reminders',
        '智能便签提醒',
        description: '便签闹钟和系统提醒',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    final canScheduleExact = await android?.canScheduleExactNotifications();
    if (canScheduleExact == false) {
      await android?.requestExactAlarmsPermission();
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _ready = true;
  }

  Future<void> schedule(NoteModel note, {bool createSystemAlarm = true}) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    await cancel(note.id);
    if (note.reminderAt == null || !note.reminderAt!.isAfter(DateTime.now())) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'smart_note_ai_reminders',
        '智能便签提醒',
        channelDescription: '便签闹钟和系统提醒',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    await _scheduleWithRepeat(note, details);

    if (createSystemAlarm) {
      await _tryNativeAlarm(note);
    }
  }

  Future<void> cancel(String noteId) {
    if (kIsWeb) return Future<void>.value();
    return _plugin.cancel(id: _intId(noteId));
  }

  Future<void> reschedulePending(List<NoteModel> notes) async {
    if (kIsWeb) return;
    for (final note in notes) {
      if (note.reminderAt != null && note.reminderAt!.isAfter(DateTime.now())) {
        await schedule(note, createSystemAlarm: false);
      }
    }
  }

  Future<void> _scheduleWithRepeat(
    NoteModel note,
    NotificationDetails details,
  ) async {
    var date = tz.TZDateTime.from(note.reminderAt!, tz.local);
    
    // 如果提醒时间已经过去，计算下次提醒时间
    final now = tz.TZDateTime.now(tz.local);
    if (date.isBefore(now)) {
      date = _calculateNextReminder(note, now);
    }

    // 重复提醒将在应用启动时通过 reschedulePending 重新调度

    for (final mode in const [
      AndroidScheduleMode.alarmClock,
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id: _intId(note.id),
          title: note.title,
          body: note.content,
          scheduledDate: date,
          notificationDetails: details,
          androidScheduleMode: mode,
        );
        return;
      } catch (_) {}
    }
  }

  tz.TZDateTime _calculateNextReminder(NoteModel note, tz.TZDateTime now) {
    var nextDate = tz.TZDateTime.from(note.reminderAt!, tz.local);
    
    while (nextDate.isBefore(now)) {
      switch (note.reminderRepeat) {
        case ReminderRepeat.daily:
          nextDate = nextDate.add(const Duration(days: 1));
          break;
        case ReminderRepeat.weekly:
          nextDate = nextDate.add(const Duration(days: 7));
          break;
        case ReminderRepeat.monthly:
          nextDate = nextDate.add(const Duration(days: 30));
          break;
        case ReminderRepeat.none:
          return now.add(const Duration(minutes: 1));
      }
    }
    return nextDate;
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
        'android.intent.extra.alarm.SKIP_UI': true,
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

  Future<void> _initTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
  }
}
