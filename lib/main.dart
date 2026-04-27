import 'dart:convert';
import 'dart:ui';

import 'package:android_intent_plus/android_intent.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN');
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

  final notifications = NotificationService();
  await notifications.init();
  final store = AppStore(notifications);
  await store.load();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: notifications),
        ChangeNotifierProvider.value(value: store),
      ],
      child: const SmartNoteApp(),
    ),
  );
}

class SmartNoteApp extends StatelessWidget {
  const SmartNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFFE88A);
    const ink = Color(0xFF172033);
    final textTheme = GoogleFonts.notoSansScTextTheme().apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '智能便签',
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: const Color(0xFFB5E7A1),
          tertiary: const Color(0xFFB8D7FF),
          surface: const Color(0xFFFFFBF3),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBF3),
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: ink,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFF8D8).withValues(alpha: 0.55),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD84D), width: 1.2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            backgroundColor: const Color(0xFFFFE88A),
            foregroundColor: const Color(0xFF2B2A25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFE88A),
          foregroundColor: Color(0xFF2B2A25),
          elevation: 5,
          shape: CircleBorder(),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: const Color(0xFFFFFBF3),
          headerBackgroundColor: const Color(0xFFFFE88A),
          headerForegroundColor: const Color(0xFF2B2A25),
          todayForegroundColor: WidgetStateProperty.all(
            const Color(0xFF2B2A25),
          ),
          todayBorder: const BorderSide(color: Color(0xFFFFD84D), width: 1.4),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF2B2A25);
            }
            return const Color(0xFF172033);
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFFFE88A);
            }
            return null;
          }),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

enum TaskPriority { low, medium, high }

extension TaskPriorityMeta on TaskPriority {
  String get label => switch (this) {
    TaskPriority.low => '低',
    TaskPriority.medium => '中',
    TaskPriority.high => '高',
  };

  Color get color => switch (this) {
    TaskPriority.low => const Color(0xFF54A58A),
    TaskPriority.medium => const Color(0xFF2F6DF6),
    TaskPriority.high => const Color(0xFFE86C52),
  };
}

class Note {
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.reminderAt,
    this.done = false,
    this.priority = TaskPriority.medium,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? reminderAt;
  final bool done;
  final TaskPriority priority;

  Note copyWith({
    String? title,
    String? content,
    DateTime? reminderAt,
    bool clearReminder = false,
    bool? done,
    TaskPriority? priority,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      reminderAt: clearReminder ? null : reminderAt ?? this.reminderAt,
      done: done ?? this.done,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'done': done,
    'priority': priority.name,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    reminderAt: json['reminderAt'] == null
        ? null
        : DateTime.parse(json['reminderAt'] as String),
    done: json['done'] as bool? ?? false,
    priority: TaskPriority.values.firstWhere(
      (item) => item.name == json['priority'],
      orElse: () => TaskPriority.medium,
    ),
  );
}

class AiPreset {
  const AiPreset(this.name, this.baseUrl, this.model, this.homepage, this.tip);

  final String name;
  final String baseUrl;
  final String model;
  final String homepage;
  final String tip;
}

const aiPresets = [
  AiPreset(
    'OpenAI',
    'https://api.openai.com/v1',
    'gpt-4o',
    'https://platform.openai.com/api-keys',
    '创建接口密钥后保持默认接口地址即可。',
  ),
  AiPreset(
    'Anthropic',
    'https://api.anthropic.com/v1',
    'claude-3-5-sonnet-latest',
    'https://console.anthropic.com/settings/keys',
    'Anthropic 接口格式不同，建议正式版通过后端适配。',
  ),
  AiPreset(
    'Google Gemini',
    'https://generativelanguage.googleapis.com/v1beta',
    'gemini-1.5-pro',
    'https://aistudio.google.com/app/apikey',
    'Gemini 接口格式不同，建议正式版通过后端适配。',
  ),
  AiPreset(
    'DeepSeek',
    'https://api.deepseek.com/v1',
    'deepseek-chat',
    'https://platform.deepseek.com/api_keys',
    '兼容 OpenAI 聊天补全接口。',
  ),
  AiPreset(
    'Moonshot',
    'https://api.moonshot.cn/v1',
    'moonshot-v1-8k',
    'https://platform.moonshot.cn/console/api-keys',
    '兼容 OpenAI 调用格式。',
  ),
  AiPreset(
    '智谱AI',
    'https://open.bigmodel.cn/api/paas/v4',
    'glm-4-plus',
    'https://open.bigmodel.cn/usercenter/apikeys',
    '新版接口兼容聊天补全接口。',
  ),
  AiPreset(
    '通义千问',
    'https://dashscope.aliyuncs.com/compatible-mode/v1',
    'qwen-plus',
    'https://dashscope.console.aliyun.com/apiKey',
    '使用通义兼容模式可按 OpenAI 风格请求。',
  ),
];

String normalizeProviderName(String value) {
  return switch (value) {
    '开放智能' => 'OpenAI',
    '安索智能' => 'Anthropic',
    '谷歌双子' => 'Google Gemini',
    '智谱智能' => '智谱AI',
    _ => value,
  };
}

class AiConfig {
  const AiConfig({
    this.provider = 'OpenAI',
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o',
  });

  final String provider;
  final String apiKey;
  final String baseUrl;
  final String model;

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'model': model,
  };

  factory AiConfig.fromJson(Map<String, dynamic> json) => AiConfig(
    provider: normalizeProviderName(json['provider'] as String? ?? 'OpenAI'),
    apiKey: json['apiKey'] as String? ?? '',
    baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
    model: json['model'] as String? ?? 'gpt-4o',
  );
}

class GeneratedTask {
  const GeneratedTask({
    required this.title,
    required this.content,
    this.reminderAt,
    this.priority = TaskPriority.medium,
  });

  final String title;
  final String content;
  final DateTime? reminderAt;
  final TaskPriority priority;
}

DateTime _plannedAt(Note note) => note.reminderAt ?? note.createdAt;

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

class AppStore extends ChangeNotifier {
  AppStore(this._notifications);

  static const _notesKey = 'smart_note_ai_notes';
  static const _configKey = 'smart_note_ai_config';

  final NotificationService _notifications;
  final List<Note> _notes = [];
  AiConfig _config = const AiConfig();
  DateTime _archiveDate = DateTime.now();

  List<Note> get notes => List.unmodifiable(
    [..._notes]..sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return (a.reminderAt ?? a.createdAt).compareTo(
        b.reminderAt ?? b.createdAt,
      );
    }),
  );

  AiConfig get config => _config;
  DateTime get archiveDate => _archiveDate;
  int get doneCount => _notes.where((note) => note.done).length;
  int get pendingCount => _notes.length - doneCount;
  int get totalCount => _notes.length;
  int get highPriorityDoneCount => _notes
      .where((note) => note.done && note.priority == TaskPriority.high)
      .length;
  double get completionRate => totalCount == 0 ? 0 : doneCount / totalCount;

  List<DateTime> get archiveDates {
    final dates = <DateTime>{};
    for (final note in _notes) {
      dates.add(_dateOnly(_plannedAt(note)));
    }
    return dates.toList()..sort((a, b) => b.compareTo(a));
  }

  List<Note> get notesOnArchiveDate {
    final selected = _dateOnly(_archiveDate);
    return notes
        .where((note) => _dateOnly(_plannedAt(note)).isAtSameMomentAs(selected))
        .toList();
  }

  List<Note> get notesBeforeArchiveDate {
    final selected = _dateOnly(_archiveDate);
    return notes
        .where((note) => _dateOnly(_plannedAt(note)).isBefore(selected))
        .toList();
  }

  int get activeDays => archiveDates.length;

  int get currentStreak {
    final doneDays = _notes
        .where((note) => note.done)
        .map((note) => _dateOnly(_plannedAt(note)))
        .toSet();
    var cursor = _dateOnly(DateTime.now());
    var streak = 0;
    while (doneDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void setArchiveDate(DateTime date) {
    _archiveDate = _dateOnly(date);
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawNotes = prefs.getString(_notesKey);
    final rawConfig = prefs.getString(_configKey);
    if (rawNotes == null) {
      _notes.addAll(_seedNotes());
      await _saveNotes();
    } else {
      final decoded = jsonDecode(rawNotes) as List<dynamic>;
      _notes
        ..clear()
        ..addAll(
          decoded.map((item) => Note.fromJson(item as Map<String, dynamic>)),
        );
    }
    if (rawConfig != null) {
      _config = AiConfig.fromJson(
        jsonDecode(rawConfig) as Map<String, dynamic>,
      );
    }
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    _notes.add(note);
    await _saveNotes();
    await _notifications.schedule(note);
    notifyListeners();
  }

  Future<void> addTasks(List<GeneratedTask> tasks) async {
    for (final task in tasks) {
      final note = Note(
        id: _uuid.v4(),
        title: task.title,
        content: task.content,
        createdAt: DateTime.now(),
        reminderAt: task.reminderAt,
        priority: task.priority,
      );
      _notes.add(note);
      await _notifications.schedule(note);
    }
    await _saveNotes();
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((item) => item.id == note.id);
    if (index < 0) return;
    _notes[index] = note;
    await _saveNotes();
    await _notifications.schedule(note);
    notifyListeners();
  }

  Future<void> toggleDone(String id) async {
    final index = _notes.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _notes[index] = _notes[index].copyWith(done: !_notes[index].done);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((item) => item.id == id);
    await _notifications.cancel(id);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> saveConfig(AiConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
    notifyListeners();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notesKey,
      jsonEncode(_notes.map((e) => e.toJson()).toList()),
    );
  }

  List<Note> _seedNotes() {
    final now = DateTime.now();
    return [
      Note(
        id: _uuid.v4(),
        title: '学习跨平台开发',
        content: '整理状态管理方案的使用差异，完成一个小型演示。',
        createdAt: now.subtract(const Duration(hours: 3)),
        reminderAt: DateTime(now.year, now.month, now.day, 20),
        priority: TaskPriority.high,
      ),
      Note(
        id: _uuid.v4(),
        title: '健身计划',
        content: '晚上跑步 40 分钟，结束后记录心率和配速。',
        createdAt: now.subtract(const Duration(days: 1)),
        reminderAt: DateTime(now.year, now.month, now.day, 21),
      ),
      Note(
        id: _uuid.v4(),
        title: '配置接口',
        content: '到我的页面填写服务商、接口地址、模型名称和接口密钥。',
        createdAt: now.subtract(const Duration(days: 2)),
        done: true,
        priority: TaskPriority.low,
      ),
    ];
  }
}

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final androidNotifications = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidNotifications != null) {
      final canScheduleExact = await androidNotifications
          .canScheduleExactNotifications();
      if (canScheduleExact == false) {
        await androidNotifications.requestExactAlarmsPermission();
      }
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> schedule(Note note) async {
    if (kIsWeb) return;

    await cancel(note.id);
    final reminder = note.reminderAt;
    if (reminder == null || reminder.isBefore(DateTime.now())) return;

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
        scheduledDate: tz.TZDateTime.from(reminder, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: _intId(note.id),
        title: note.title,
        body: note.content,
        scheduledDate: tz.TZDateTime.from(reminder, tz.local),
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

  Future<void> _tryNativeAlarm(Note note) async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        note.reminderAt == null) {
      return;
    }
    final time = note.reminderAt!;
    final intent = AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': time.hour,
        'android.intent.extra.alarm.MINUTES': time.minute,
        'android.intent.extra.alarm.MESSAGE': '智能便签：${note.title}',
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

class AiService {
  AiService(this.config);

  final AiConfig config;

  Future<List<GeneratedTask>> generate(String prompt) async {
    if (config.apiKey.trim().isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      return _mock(prompt);
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl.replaceAll(RegExp(r'/$'), ''),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 18),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final response = await dio.post<Map<String, dynamic>>(
      '/chat/completions',
      data: {
        'model': config.model,
        'temperature': 0.35,
        'messages': [
          {
            'role': 'system',
            'content': '你是智能便签助手。只返回结构化数组，每项包含标题、内容、时间和优先级字段。',
          },
          {'role': 'user', 'content': prompt},
        ],
      },
    );

    final content = response.data?['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('智能服务未返回有效内容');
    }
    return _parse(content, prompt);
  }

  List<GeneratedTask> _parse(String raw, String fallbackPrompt) {
    final clean = raw
        .replaceAll(RegExp(r'```json|```', caseSensitive: false), '')
        .trim();
    try {
      final decoded = jsonDecode(clean) as List<dynamic>;
      return decoded.map((item) {
        final map = item as Map<String, dynamic>;
        return GeneratedTask(
          title: map['title'] as String? ?? '智能任务',
          content: map['content'] as String? ?? fallbackPrompt,
          reminderAt: _timeOfTodayOrTomorrow(map['time'] as String?),
          priority: TaskPriority.values.firstWhere(
            (p) => p.name == map['priority'],
            orElse: () => TaskPriority.medium,
          ),
        );
      }).toList();
    } catch (_) {
      final lines = clean
          .split(RegExp(r'\n+'))
          .where((line) => line.trim().isNotEmpty)
          .take(8);
      return lines.map((line) {
        final text = line.trim();
        final time = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(text)?.group(0);
        return GeneratedTask(
          title: text.replaceFirst(RegExp(r'^\d{1,2}:\d{2}\s*'), ''),
          content: '由智能服务根据「$fallbackPrompt」生成',
          reminderAt: _timeOfTodayOrTomorrow(time),
        );
      }).toList();
    }
  }

  List<GeneratedTask> _mock(String prompt) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day + 1);
    final workout = prompt.contains('健身') || prompt.contains('减脂');
    if (workout) {
      return [
        GeneratedTask(
          title: '热身拉伸',
          content: '动态拉伸 8 分钟，激活肩、髋、膝关节。',
          reminderAt: base.add(const Duration(hours: 7)),
          priority: TaskPriority.low,
        ),
        GeneratedTask(
          title: '力量训练',
          content: '深蹲、俯卧撑、划船各 4 组，组间休息 60 秒。',
          reminderAt: base.add(const Duration(hours: 19)),
          priority: TaskPriority.high,
        ),
        GeneratedTask(
          title: '有氧收尾',
          content: '慢跑或椭圆机 25 分钟，保持可说话强度。',
          reminderAt: base.add(const Duration(hours: 20)),
        ),
      ];
    }
    return [
      GeneratedTask(
        title: '晨间梳理',
        content: '列出今天最重要的三件事，先做最消耗精力的一项。',
        reminderAt: base.add(const Duration(hours: 8)),
        priority: TaskPriority.high,
      ),
      GeneratedTask(
        title: '专注学习',
        content: '安排 2 个 45 分钟番茄钟，结束后写 5 行复盘。',
        reminderAt: base.add(const Duration(hours: 10)),
        priority: TaskPriority.high,
      ),
      GeneratedTask(
        title: '晚间整理',
        content: '归档笔记、清空收件箱，准备明天第一步。',
        reminderAt: base.add(const Duration(hours: 21)),
      ),
    ];
  }

  DateTime? _timeOfTodayOrTomorrow(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final now = DateTime.now();
    final time = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
    return time.isBefore(now) ? time.add(const Duration(days: 1)) : time;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      MobileHomePage(
        onNavigate: (index) => setState(() => _index = index),
        onAdd: _openEditor,
        onOpenAchievements: _openAchievements,
        onOpenProfile: _openProfile,
      ),
      const NotesPage(),
      const TaskPage(),
      const ArchivePage(),
    ];
    final titles = ['首页', '笔记', '任务', '日历'];
    return Scaffold(
      extendBody: true,
      appBar: _index == 0
          ? null
          : AppBar(
              title: Text(
                titles[_index],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton.filledTonal(
                    tooltip: '设置',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: _openProfile,
                  ),
                ),
              ],
            ),
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBackground()),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: pages[_index],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: StickyBottomNav(
            selectedIndex: _index,
            onChanged: (index) => setState(() => _index = index),
            onAdd: _openEditor,
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor() async {
    final note = await Navigator.of(
      context,
    ).push<Note>(MaterialPageRoute(builder: (_) => const NoteEditorPage()));
    if (note != null && mounted) {
      await context.read<AppStore>().addNote(note);
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const FeatureScaffold(title: '我的', child: ProfilePage()),
      ),
    );
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const FeatureScaffold(title: '成就徽章', child: AchievementPage()),
      ),
    );
  }
}

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBackground()),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppColors {
  static const bg = Color(0xFFFFFCF4);
  static const textPrimary = Color(0xFF222222);
  static const textSecondary = Color(0xFF777777);
  static const yellow = Color(0xFFFFEE88);
  static const green = Color(0xFFB9E7A1);
  static const pink = Color(0xFFFFB7C5);
  static const blue = Color(0xFFB8D7FF);
  static const purple = Color(0xFFE0CDFF);
  static const cardShadow = Color(0x22000000);
}

class MobileHomePage extends StatelessWidget {
  const MobileHomePage({
    super.key,
    required this.onNavigate,
    required this.onAdd,
    required this.onOpenAchievements,
    required this.onOpenProfile,
  });

  final ValueChanged<int> onNavigate;
  final VoidCallback onAdd;
  final VoidCallback onOpenAchievements;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final notes = store.notes;
    final wallNotes = _homeWallNotes(notes);
    final tasks = notes.take(3).toList();
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: HomeTopBar(onMenu: onOpenProfile, onProfile: onOpenProfile),
          ),
          const SliverToBoxAdapter(child: WelcomeStickyCard()),
          SliverToBoxAdapter(
            child: SectionHeader(title: '快捷记录', action: '全部', onTap: onAdd),
          ),
          SliverToBoxAdapter(child: QuickInput(onTap: onAdd)),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '便签墙',
              action: '全部便签',
              onTap: () => onNavigate(1),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.crossAxisExtent - 16) / 2;
                final cardHeight = (cardWidth * 0.78).clamp(118.0, 148.0);
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final note = wallNotes[index];
                    final isPreview = note.id.startsWith('preview-');
                    return Dismissible(
                      key: ValueKey('home-${note.id}'),
                      direction: isPreview
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      dismissThresholds: const {
                        DismissDirection.endToStart: 0.2,
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE86C52),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) =>
                          context.read<AppStore>().deleteNote(note.id),
                      child: StickyWallCard(note: note),
                    );
                  }, childCount: wallNotes.length),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: cardHeight,
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '今日任务',
              action: '全部任务',
              onTap: () => onNavigate(2),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 11, child: TodayTasksCard(tasks: tasks)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 8,
                    child: MiniCalendarCard(onTap: () => onNavigate(3)),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: '成就徽章',
              action: '全部成就',
              onTap: onOpenAchievements,
            ),
          ),
          SliverToBoxAdapter(
            child: AchievementShelf(
              doneCount: store.doneCount,
              streak: store.currentStreak,
              activeDays: store.activeDays,
              onTap: onOpenAchievements,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 116)),
        ],
      ),
    );
  }

  List<Note> _homeWallNotes(List<Note> notes) {
    if (notes.length >= 4) return notes.take(4).toList();
    final now = DateTime.now();
    return [
      ...notes,
      Note(
        id: 'preview-reading',
        title: '阅读清单',
        content: '《设计心理学》\n《简约至上》',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        priority: TaskPriority.high,
      ),
      Note(
        id: 'preview-inspiration',
        title: '灵感记录',
        content: '卡片式布局\n便签风格 ✨',
        createdAt: now.subtract(const Duration(days: 1, hours: 5)),
        priority: TaskPriority.low,
      ),
    ].take(4).toList();
  }
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.onMenu, required this.onProfile});

  final VoidCallback onMenu;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: Row(
        children: [
          IconButton(
            tooltip: '菜单',
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded, size: 32),
          ),
          const Spacer(),
          const Text(
            '首页',
            style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          IconButton(
            tooltip: '搜索',
            onPressed: () {},
            icon: const Icon(Icons.search_rounded, size: 34),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfile,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF0FF),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('👩🏻', style: TextStyle(fontSize: 25)),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeStickyCard extends StatelessWidget {
  const WelcomeStickyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: Container(
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF6B8), AppColors.yellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFFDD68)),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              right: -12,
              top: -24,
              child: Icon(
                Icons.star_rounded,
                color: Color(0xFFFFC928),
                size: 33,
              ),
            ),
            Positioned(
              right: -18,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD85A).withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '👋  你好，今天也要加油呀！',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 12),
                Text(
                  '专注当下，未来可期 ✨',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Text(
                    action,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickInput extends StatelessWidget {
  const QuickInput({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.yellow.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFFD85A).withValues(alpha: 0.5),
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '记录一下你的想法...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDA55).withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StickyWallCard extends StatefulWidget {
  const StickyWallCard({super.key, required this.note});

  final Note note;

  @override
  State<StickyWallCard> createState() => _StickyWallCardState();
}

class _StickyWallCardState extends State<StickyWallCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final paperColor = _wallPaperColor(note);
    final accent = _wallAccentColor(note);
    final lines = _notePreviewLines(note);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () async {
        if (note.id.startsWith('preview-')) return;
        final updated = await Navigator.of(context).push<Note>(
          MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
        );
        if (updated != null && context.mounted) {
          await context.read<AppStore>().updateNote(updated);
        }
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 16, 13, 12),
          decoration: BoxDecoration(
            color: paperColor,
            borderRadius: BorderRadius.circular(7),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 13,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -10,
                top: -14,
                child: Transform.rotate(
                  angle: note.priority == TaskPriority.high ? 0.16 : -0.2,
                  child: Icon(
                    note.priority == TaskPriority.medium
                        ? Icons.star_rounded
                        : Icons.push_pin_rounded,
                    size: note.priority == TaskPriority.medium ? 31 : 28,
                    color: accent,
                  ),
                ),
              ),
              Positioned(
                right: -14,
                bottom: -16,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      decoration: note.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $line',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.28),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _relativeTimeLabel(note.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TodayTasksCard extends StatelessWidget {
  const TodayTasksCard({super.key, required this.tasks});

  final List<Note> tasks;

  @override
  Widget build(BuildContext context) {
    final visibleTasks = tasks.isEmpty
        ? [
            Note(
              id: 'task-empty-1',
              title: '设计评审会议',
              content: '',
              createdAt: DateTime.now(),
              reminderAt: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                10,
              ),
            ),
            Note(
              id: 'task-empty-2',
              title: '收集用户反馈',
              content: '',
              createdAt: DateTime.now(),
              done: true,
              reminderAt: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                11,
                30,
              ),
            ),
            Note(
              id: 'task-empty-3',
              title: '输出设计方案',
              content: '',
              createdAt: DateTime.now(),
              reminderAt: DateTime(
                DateTime.now().year,
                DateTime.now().month,
                DateTime.now().day,
                15,
              ),
            ),
          ]
        : tasks;
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: _paperDecoration(Colors.white, radius: 10),
      child: Column(
        children: [
          for (var i = 0; i < visibleTasks.take(3).length; i++) ...[
            Expanded(child: TaskMiniRow(note: visibleTasks[i])),
            if (i != visibleTasks.take(3).length - 1)
              Divider(
                height: 1,
                color: const Color(0xFFEBDDC8).withValues(alpha: 0.65),
              ),
          ],
        ],
      ),
    );
  }
}

class TaskMiniRow extends StatelessWidget {
  const TaskMiniRow({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final isPreview = note.id.startsWith('task-empty-');
    return InkWell(
      onTap: isPreview
          ? null
          : () => context.read<AppStore>().toggleDone(note.id),
      child: Row(
        children: [
          Icon(
            note.done
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            size: 21,
            color: note.done
                ? const Color(0xFF54A58A)
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                decoration: note.done ? TextDecoration.lineThrough : null,
                color: note.done
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            note.reminderAt == null
                ? ''
                : DateFormat('HH:mm').format(note.reminderAt!),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (!note.done) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.star_border_rounded,
              size: 19,
              color: Color(0xFFB8AA8A),
            ),
          ],
        ],
      ),
    );
  }
}

class MiniCalendarCard extends StatelessWidget {
  const MiniCalendarCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month);
    final leading = first.weekday % 7;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final cells = <int?>[
      for (var i = 0; i < leading; i++) null,
      for (var day = 1; day <= daysInMonth; day++) day,
    ];
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 9),
        decoration: _paperDecoration(Colors.white, radius: 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -9,
              top: -20,
              child: Transform.rotate(
                angle: -0.28,
                child: Container(
                  width: 46,
                  height: 16,
                  color: const Color(0xFFFFE2A6).withValues(alpha: 0.9),
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.chevron_left_rounded, size: 18),
                    const Spacer(),
                    Text(
                      '${now.month}月  ${now.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
                const SizedBox(height: 7),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CalendarLabel('日'),
                    _CalendarLabel('一'),
                    _CalendarLabel('二'),
                    _CalendarLabel('三'),
                    _CalendarLabel('四'),
                    _CalendarLabel('五'),
                    _CalendarLabel('六'),
                  ],
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: 42,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                    itemBuilder: (_, index) {
                      final day = index < cells.length ? cells[index] : null;
                      final selected = day == now.day;
                      return Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.yellow
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            day == null ? '' : '$day',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: day == null
                                  ? AppColors.textSecondary.withValues(
                                      alpha: 0.35,
                                    )
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarLabel extends StatelessWidget {
  const _CalendarLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
    );
  }
}

class AchievementShelf extends StatelessWidget {
  const AchievementShelf({
    super.key,
    required this.doneCount,
    required this.streak,
    required this.activeDays,
    required this.onTap,
  });

  final int doneCount;
  final int streak;
  final int activeDays;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badges = [
      AchievementView('初来乍到', '创建第一个笔记', Icons.star_rounded, AppColors.yellow),
      AchievementView(
        '坚持记录',
        '连续记录 $streak 天',
        Icons.verified_rounded,
        AppColors.green,
      ),
      AchievementView(
        '高效达人',
        '完成 $doneCount 个任务',
        Icons.workspace_premium_rounded,
        AppColors.pink,
      ),
      AchievementView(
        '灵感捕手',
        '活跃 $activeDays 天',
        Icons.military_tech_rounded,
        AppColors.blue,
      ),
      const AchievementView(
        '整理大师',
        '归档 50 条内容',
        Icons.diamond_rounded,
        AppColors.purple,
      ),
    ];
    return SizedBox(
      height: 128,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) =>
            AchievementBadgeCard(badge: badges[index], onTap: onTap),
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemCount: badges.length,
      ),
    );
  }
}

class AchievementBadgeCard extends StatelessWidget {
  const AchievementBadgeCard({
    super.key,
    required this.badge,
    required this.onTap,
  });

  final AchievementView badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stroke = Color.lerp(badge.color, Colors.black, 0.34)!;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 78,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
        decoration: _paperDecoration(badge.color, radius: 8),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -17,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Color.lerp(badge.color, Colors.white, 0.25),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(badge.icon, size: 40, color: stroke),
                const SizedBox(height: 8),
                Text(
                  badge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  badge.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementView {
  const AchievementView(this.title, this.desc, this.icon, this.color);

  final String title;
  final String desc;
  final IconData icon;
  final Color color;
}

class StickyBottomNav extends StatelessWidget {
  const StickyBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          NavItem(
            icon: Icons.home_rounded,
            label: '首页',
            active: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          NavItem(
            icon: Icons.edit_note_rounded,
            label: '笔记',
            active: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
          AddNavButton(onTap: onAdd),
          NavItem(
            icon: Icons.check_box_outlined,
            label: '任务',
            active: selectedIndex == 2,
            onTap: () => onChanged(2),
          ),
          NavItem(
            icon: Icons.calendar_month_rounded,
            label: '日历',
            active: selectedIndex == 3,
            onTap: () => onChanged(3),
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 54,
        height: 58,
        decoration: BoxDecoration(
          color: active
              ? AppColors.yellow.withValues(alpha: 0.75)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 25, color: AppColors.textPrimary),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class AddNavButton extends StatefulWidget {
  const AddNavButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AddNavButton> createState() => _AddNavButtonState();
}

class _AddNavButtonState extends State<AddNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.96,
      upperBound: 1.04,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: AppColors.yellow,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 13,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 36),
        ),
      ),
    );
  }
}

class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<AppStore>().notes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 84, 18, 118),
      children: [
        TodayTasksCard(tasks: notes.take(3).toList()),
        const SizedBox(height: 18),
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: NoteCard(note: note),
          ),
      ],
    );
  }
}

BoxDecoration _paperDecoration(Color color, {double radius = 14}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(
        color: AppColors.cardShadow,
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  );
}

Color _wallPaperColor(Note note) {
  if (note.id == 'preview-inspiration') {
    return AppColors.blue.withValues(alpha: 0.86);
  }
  if (note.id == 'preview-reading') {
    return AppColors.pink.withValues(alpha: 0.76);
  }
  return switch (note.priority) {
    TaskPriority.high => AppColors.pink.withValues(alpha: 0.72),
    TaskPriority.medium => AppColors.yellow.withValues(alpha: 0.78),
    TaskPriority.low => AppColors.green.withValues(alpha: 0.78),
  };
}

Color _wallAccentColor(Note note) {
  if (note.id == 'preview-inspiration') return const Color(0xFF5297FF);
  if (note.id == 'preview-reading') return const Color(0xFFFF7892);
  return switch (note.priority) {
    TaskPriority.high => const Color(0xFFFF7892),
    TaskPriority.medium => const Color(0xFFFFC928),
    TaskPriority.low => const Color(0xFF78D46D),
  };
}

List<String> _notePreviewLines(Note note) {
  return note.content
      .split(RegExp(r'[\n，,。；;]+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .take(2)
      .toList();
}

String _relativeTimeLabel(DateTime date) {
  final now = DateTime.now();
  final today = _dateOnly(now);
  final day = _dateOnly(date);
  final time = DateFormat('HH:mm').format(date);
  if (day.isAtSameMomentAs(today)) return '今天 $time';
  if (day.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
    return '昨天 $time';
  }
  return DateFormat('M月d日 HH:mm').format(date);
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final notes = store.notes;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 104, 18, 118),
      children: [
        SummaryCard(
          done: store.doneCount,
          pending: store.pendingCount,
          total: notes.length,
        ),
        const SizedBox(height: 18),
        if (notes.isEmpty) const EmptyState(),
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: NoteCard(note: note),
          ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.done,
    required this.pending,
    required this.total,
  });

  final int done;
  final int pending;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE88A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF2B2A25)),
              ),
              const SizedBox(height: 12),
              Text(
                DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now()),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF667085)),
              ),
              const Text(
                '下一代智能任务助手',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFFFF6C8),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD84D)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatPill(label: '已完成', value: '$done'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatPill(label: '待完成', value: '$pending'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF667085))),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

Color _notePaperColor(Note note) {
  if (note.done) return const Color(0xFFF6F6F6);
  return switch (note.priority) {
    TaskPriority.high => const Color(0xFFFFB7C5),
    TaskPriority.medium => const Color(0xFFFFE88A),
    TaskPriority.low => const Color(0xFFB5E7A1),
  };
}

Color _notePinColor(Note note) {
  if (note.done) return const Color(0xFF98A2B3);
  return switch (note.priority) {
    TaskPriority.high => const Color(0xFFE86C52),
    TaskPriority.medium => const Color(0xFFC28100),
    TaskPriority.low => const Color(0xFF54A58A),
  };
}

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final color = note.done ? const Color(0xFF98A2B3) : const Color(0xFF172033);
    final paperColor = _notePaperColor(note);
    final pinColor = _notePinColor(note);
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.2,
        DismissDirection.endToStart: 0.2,
      },
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => store.deleteNote(note.id),
      background: const DismissBg(alignment: Alignment.centerLeft),
      secondaryBackground: const DismissBg(alignment: Alignment.centerRight),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final updated = await Navigator.of(context).push<Note>(
            MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
          );
          if (updated != null && context.mounted) {
            await context.read<AppStore>().updateNote(updated);
          }
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: paperColor.withValues(alpha: note.done ? 0.72 : 0.62),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -4,
                right: 10,
                child: Transform.rotate(
                  angle: 0.18,
                  child: Icon(
                    Icons.push_pin_rounded,
                    color: pinColor,
                    size: 22,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    selected: note.done,
                    label: note.done ? '标记为未完成' : '标记为已完成',
                    child: IconButton(
                      tooltip: note.done ? '标记为未完成' : '标记为已完成',
                      style: IconButton.styleFrom(
                        fixedSize: const Size(38, 38),
                        backgroundColor: Colors.white.withValues(alpha: 0.72),
                        foregroundColor: pinColor,
                      ),
                      onPressed: () => store.toggleDone(note.id),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          note.done
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          key: ValueKey(note.done),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 38),
                          child: Text(
                            note.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: color,
                              decoration: note.done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color.withValues(alpha: 0.78),
                            height: 1.5,
                            decoration: note.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PriorityBadge(priority: note.priority),
                            MetaChip(
                              icon: Icons.schedule_rounded,
                              label: note.reminderAt == null
                                  ? '未设置提醒'
                                  : DateFormat(
                                      'MM/dd HH:mm',
                                    ).format(note.reminderAt!),
                            ),
                            MetaChip(
                              icon: Icons.calendar_today_rounded,
                              label: DateFormat(
                                'MM/dd HH:mm',
                              ).format(note.createdAt),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('确认删除该便签？'),
      content: Text('「${note.title}」删除后不可恢复。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确认'),
        ),
      ],
    ),
  );
}

class DismissBg extends StatelessWidget {
  const DismissBg({super.key, required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 76,
        height: 76,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE86C52),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE86C52).withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
    );
  }
}

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final selected = store.archiveDate;
    final onDay = store.notesOnArchiveDate;
    final beforeDay = store.notesBeforeArchiveDate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 104, 18, 118),
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F6DF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Color(0xFF2F6DF6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '归档日期',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '查看某一天，以及这天以前留下的计划。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF667085).withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => _pickArchiveDate(context, selected),
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(selected),
                  ),
                ),
              ),
              if (store.archiveDates.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final date in store.archiveDates.take(12))
                      ChoiceChip(
                        label: Text(DateFormat('M月d日').format(date)),
                        selected: _dateOnly(
                          date,
                        ).isAtSameMomentAs(_dateOnly(selected)),
                        onSelected: (_) => store.setArchiveDate(date),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        ArchiveSection(title: '这一天的计划', notes: onDay),
        const SizedBox(height: 18),
        ArchiveSection(title: '这天以前的计划', notes: beforeDay),
      ],
    );
  }

  Future<void> _pickArchiveDate(BuildContext context, DateTime selected) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(now.year - 5),
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('zh', 'CN'),
      helpText: '选择归档日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null && context.mounted) {
      context.read<AppStore>().setArchiveDate(picked);
    }
  }
}

class ArchiveSection extends StatelessWidget {
  const ArchiveSection({super.key, required this.title, required this.notes});

  final String title;
  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '$title · ${notes.length}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 10),
        if (notes.isEmpty)
          GlassPanel(
            padding: const EdgeInsets.all(20),
            child: Text(
              '这里暂时没有计划。',
              style: TextStyle(
                color: const Color(0xFF667085).withValues(alpha: 0.9),
              ),
            ),
          )
        else
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ArchiveNoteCard(note: note),
            ),
      ],
    );
  }
}

class ArchiveNoteCard extends StatelessWidget {
  const ArchiveNoteCard({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final paperColor = _notePaperColor(note);
    final pinColor = _notePinColor(note);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: paperColor.withValues(alpha: note.done ? 0.64 : 0.58),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: pinColor.withValues(alpha: 0.13),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              note.done ? Icons.check_rounded : Icons.description_outlined,
              color: pinColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    decoration: note.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '归档时间：${DateFormat('yyyy/MM/dd').format(note.createdAt)}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PriorityBadge(priority: note.priority),
        ],
      ),
    );
  }
}

class AchievementPage extends StatelessWidget {
  const AchievementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final rate = store.completionRate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 104, 18, 118),
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC857).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFC28100),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '完成不是清空列表，而是在给自己留下证据。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE6ECF7),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFC857)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '完成率 ${(rate * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF667085)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.18,
          children: [
            AchievementMetric(
              icon: Icons.done_all_rounded,
              label: '完成总数',
              value: '${store.doneCount}',
              color: const Color(0xFF54A58A),
            ),
            AchievementMetric(
              icon: Icons.local_fire_department_rounded,
              label: '连续天数',
              value: '${store.currentStreak}',
              color: const Color(0xFFE86C52),
            ),
            AchievementMetric(
              icon: Icons.calendar_month_rounded,
              label: '活跃日期',
              value: '${store.activeDays}',
              color: const Color(0xFF2F6DF6),
            ),
            AchievementMetric(
              icon: Icons.flag_rounded,
              label: '高优完成',
              value: '${store.highPriorityDoneCount}',
              color: const Color(0xFF8A63D2),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '今日鼓励',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                store.doneCount == 0
                    ? '先完成一件很小的事，让今天开始有重量。'
                    : '你已经完成 ${store.doneCount} 件事，它们不是消失了，而是变成了你的轨迹。',
                style: const TextStyle(color: Color(0xFF667085), height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AchievementMetric extends StatelessWidget {
  const AchievementMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -2,
            right: -2,
            child: Transform.rotate(
              angle: -0.16,
              child: Icon(Icons.push_pin_rounded, color: color, size: 20),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 12),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF667085)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _controller = TextEditingController(text: '帮我安排明天的学习计划');
  List<GeneratedTask> _tasks = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppStore>().config;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 104, 18, 118),
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF2F6DF6)),
                  SizedBox(width: 8),
                  Text(
                    '输入你的计划需求',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(hintText: '例如：安排一周减脂训练计划'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.psychology_alt_rounded),
                  label: Text(_loading ? '生成中' : '智能生成计划'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                config.apiKey.isEmpty
                    ? '当前未填写接口密钥，将使用本地模拟生成。'
                    : '当前服务商：${config.provider} / ${config.model}',
                style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_tasks.isNotEmpty)
          GlassPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '生成结果',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.playlist_add_check_rounded),
                      label: const Text('一键添加'),
                      onPressed: () async {
                        await context.read<AppStore>().addTasks(_tasks);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已添加到首页')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                for (final task in _tasks) GeneratedTaskTile(task: task),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _generate() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;
    setState(() => _loading = true);
    try {
      final tasks = await AiService(
        context.read<AppStore>().config,
      ).generate(prompt);
      if (mounted) setState(() => _tasks = tasks);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class GeneratedTaskTile extends StatelessWidget {
  const GeneratedTaskTile({super.key, required this.task});

  final GeneratedTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: task.priority.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  task.content,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    height: 1.45,
                  ),
                ),
                if (task.reminderAt != null) ...[
                  const SizedBox(height: 8),
                  MetaChip(
                    icon: Icons.alarm_rounded,
                    label: DateFormat('MM/dd HH:mm').format(task.reminderAt!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _provider;
  late final TextEditingController _key;
  late final TextEditingController _baseUrl;
  late final TextEditingController _model;

  @override
  void initState() {
    super.initState();
    final config = context.read<AppStore>().config;
    final provider = normalizeProviderName(config.provider);
    _provider = aiPresets.any((item) => item.name == provider)
        ? provider
        : aiPresets.first.name;
    _key = TextEditingController(text: config.apiKey);
    _baseUrl = TextEditingController(text: config.baseUrl);
    _model = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _key.dispose();
    _baseUrl.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = aiPresets.firstWhere(
      (item) => item.name == _provider,
      orElse: () => aiPresets.first,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 104, 18, 118),
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '智能服务商设置',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _provider,
                decoration: const InputDecoration(labelText: '服务商'),
                isExpanded: true,
                menuMaxHeight: 360,
                items: aiPresets
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.name,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final selected = aiPresets.firstWhere(
                    (item) => item.name == value,
                  );
                  setState(() {
                    _provider = selected.name;
                    _baseUrl.text = selected.baseUrl;
                    _model.text = selected.model;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _key,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '接口密钥',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _baseUrl,
                decoration: const InputDecoration(
                  labelText: '接口地址',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _model,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  prefixIcon: Icon(Icons.memory_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('接入教程'),
                      onPressed: () => _showTutorial(preset),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('保存配置'),
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const GlassPanel(
          padding: EdgeInsets.all(20),
          child: Text(
            '第一版已覆盖：便签增删改查、完成状态、滑动删除、编辑、提醒时间、智能自动生成、服务商配置和本地持久化。',
            style: TextStyle(color: Color(0xFF667085), height: 1.6),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    await context.read<AppStore>().saveConfig(
      AiConfig(
        provider: _provider,
        apiKey: _key.text.trim(),
        baseUrl: _baseUrl.text.trim(),
        model: _model.text.trim(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('配置已保存')));
    }
  }

  void _showTutorial(AiPreset preset) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${preset.name} 接入教程',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TutorialLinkRow(url: preset.homepage),
            const TutorialLine(
              icon: Icons.key_rounded,
              text: '创建接口密钥后粘贴到上方输入框。',
            ),
            TutorialLine(icon: Icons.settings_rounded, text: preset.tip),
            const SizedBox(height: 12),
            const Text('常见报错：401 是密钥错误；404 多半是接口地址或模型名不匹配；429 表示限流或余额不足。'),
          ],
        ),
      ),
    );
  }
}

class TutorialLinkRow extends StatelessWidget {
  const TutorialLinkRow({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.public_rounded, size: 18, color: Color(0xFF2F6DF6)),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openUrl(context),
              child: Text(
                url,
                style: const TextStyle(
                  color: Color(0xFF2F6DF6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '复制链接',
            onPressed: () => _copyUrl(context),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      await _copyUrl(context);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开浏览器，已复制链接')));
      }
    }
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('链接已复制')));
    }
  }
}

class TutorialLine extends StatelessWidget {
  const TutorialLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2F6DF6)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({super.key, this.note});

  final Note? note;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  DateTime? _reminderAt;
  late bool _done;
  late TaskPriority _priority;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _title = TextEditingController(text: note?.title ?? '');
    _content = TextEditingController(text: note?.content ?? '');
    _reminderAt = note?.reminderAt;
    _done = note?.done ?? false;
    _priority = note?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? '编辑便签' : '新增便签'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBackground()),
          ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
            children: [
              GlassPanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: '标题',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _content,
                      minLines: 6,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: '内容',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskPriority>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: '优先级',
                        prefixIcon: Icon(Icons.flag_rounded),
                      ),
                      items: TaskPriority.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text('${item.label}优先级'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _priority = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: const Text('标记为已完成'),
                      value: _done,
                      onChanged: (value) => setState(() => _done = value),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.alarm_rounded),
                      title: Text(
                        _reminderAt == null
                            ? '设置提醒时间'
                            : DateFormat(
                                'yyyy/MM/dd HH:mm',
                              ).format(_reminderAt!),
                      ),
                      subtitle: const Text('保存后注册系统提醒；安卓会打开系统闹钟确认界面'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _pickReminder,
                    ),
                    if (_reminderAt != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('清除提醒'),
                          onPressed: () => setState(() => _reminderAt = null),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _reminderAt ?? now,
      locale: const Locale('zh', 'CN'),
      helpText: '选择提醒日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _reminderAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return;
    setState(
      () => _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _save() {
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写标题和内容')));
      return;
    }
    final old = widget.note;
    final note = old == null
        ? Note(
            id: _uuid.v4(),
            title: title,
            content: content,
            createdAt: DateTime.now(),
            reminderAt: _reminderAt,
            done: _done,
            priority: _priority,
          )
        : old.copyWith(
            title: title,
            content: content,
            reminderAt: _reminderAt,
            clearReminder: _reminderAt == null,
            done: _done,
            priority: _priority,
          );
    Navigator.pop(context, note);
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${priority.label}优先级',
        style: TextStyle(
          color: priority.color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class MetaChip extends StatelessWidget {
  const MetaChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF667085)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassPanel(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.note_alt_outlined, size: 54, color: Color(0xFF98A2B3)),
          SizedBox(height: 12),
          Text(
            '还没有便签',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          SizedBox(height: 6),
          Text('点击底部加号新建，或到智能页面自动生成计划。', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF6).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFF0B5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B5F3B).withValues(alpha: 0.10),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF4), Color(0xFFFFF7DF), Color(0xFFFFFBF3)],
        ),
      ),
      child: CustomPaint(painter: _BackgroundPainter()),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;
    fill.color = const Color(0xFFFFE88A).withValues(alpha: 0.34);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.08), 124, fill);
    fill.color = const Color(0xFFB5E7A1).withValues(alpha: 0.22);
    canvas.drawCircle(Offset(size.width * 0.02, size.height * 0.24), 100, fill);

    final grid = Paint()
      ..color = const Color(0xFFD6C58B).withValues(alpha: 0.20)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
