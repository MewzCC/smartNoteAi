import 'dart:convert';
import 'dart:ui';

import 'package:android_intent_plus/android_intent.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
    const primary = Color(0xFF2F6DF6);
    const ink = Color(0xFF172033);
    final textTheme = GoogleFonts.notoSansScTextTheme().apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '智能便签',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: ink,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.78),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: primary, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
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
    '开放智能',
    'https://api.openai.com/v1',
    'gpt-4o',
    'https://platform.openai.com/api-keys',
    '创建接口密钥后保持默认接口地址即可。',
  ),
  AiPreset(
    '安索智能',
    'https://api.anthropic.com/v1',
    'claude-3-5-sonnet-latest',
    'https://console.anthropic.com/settings/keys',
    'Anthropic 接口格式不同，建议正式版通过后端适配。',
  ),
  AiPreset(
    '谷歌双子',
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
    '兼容开放智能聊天补全接口。',
  ),
  AiPreset(
    'Moonshot',
    'https://api.moonshot.cn/v1',
    'moonshot-v1-8k',
    'https://platform.moonshot.cn/console/api-keys',
    '兼容开放智能调用格式。',
  ),
  AiPreset(
    '智谱智能',
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
    '使用通义兼容模式可按开放智能风格请求。',
  ),
];

class AiConfig {
  const AiConfig({
    this.provider = '开放智能',
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
    provider: json['provider'] as String? ?? '开放智能',
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

class AppStore extends ChangeNotifier {
  AppStore(this._notifications);

  static const _notesKey = 'smart_note_ai_notes';
  static const _configKey = 'smart_note_ai_config';

  final NotificationService _notifications;
  final List<Note> _notes = [];
  AiConfig _config = const AiConfig();

  List<Note> get notes => List.unmodifiable(
    [..._notes]..sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1;
      return (a.reminderAt ?? a.createdAt).compareTo(
        b.reminderAt ?? b.createdAt,
      );
    }),
  );

  AiConfig get config => _config;
  int get doneCount => _notes.where((note) => note.done).length;
  int get pendingCount => _notes.length - doneCount;

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

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
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

    await _plugin.zonedSchedule(
      id: _intId(note.id),
      title: note.title,
      body: note.content,
      scheduledDate: tz.TZDateTime.from(reminder, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

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
        'android.intent.extra.alarm.SKIP_UI': true,
      },
    );
    try {
      await intent.launch();
    } catch (_) {}
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
    final pages = const [NotesPage(), AiPage(), ProfilePage()];
    final titles = ['今日便签', '智能生成', '我的'];
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          titles[_index],
          style: GoogleFonts.dmSerifDisplay(fontSize: 32),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              tooltip: '设置',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => setState(() => _index = 2),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBackground()),
          SafeArea(top: false, child: pages[_index]),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建'),
              onPressed: () async {
                final note = await Navigator.of(context).push<Note>(
                  MaterialPageRoute(builder: (_) => const NoteEditorPage()),
                );
                if (note != null && context.mounted) {
                  await context.read<AppStore>().addNote(note);
                }
              },
            )
          : null,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              backgroundColor: Colors.white.withValues(alpha: 0.72),
              indicatorColor: const Color(0xFF2F6DF6).withValues(alpha: 0.12),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.checklist_rounded),
                  label: '便签',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_rounded),
                  label: '智能',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_rounded),
                  label: '我的',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F6DF6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now()),
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                    const Text(
                      '下一代智能任务助手',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE6ECF7),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2F6DF6)),
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

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final color = note.done ? const Color(0xFF98A2B3) : const Color(0xFF172033);
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
        borderRadius: BorderRadius.circular(26),
        onTap: () async {
          final updated = await Navigator.of(context).push<Note>(
            MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)),
          );
          if (updated != null && context.mounted) {
            await context.read<AppStore>().updateNote(updated);
          }
        },
        child: GlassPanel(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                selected: note.done,
                label: note.done ? '标记为未完成' : '标记为已完成',
                child: IconButton.filledTonal(
                  tooltip: note.done ? '标记为未完成' : '标记为已完成',
                  onPressed: () => store.toggleDone(note.id),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      note.done
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(note.done),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        PriorityBadge(priority: note.priority),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.content,
                      maxLines: 2,
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
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFE86C52),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
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
    _provider = config.provider;
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
            TutorialLine(icon: Icons.public_rounded, text: preset.homepage),
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
                      subtitle: const Text('保存后注册本地通知，安卓会尝试调用原生闹钟'),
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
          Text('点击右下角新建，或到智能页面自动生成计划。', textAlign: TextAlign.center),
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
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D3B58).withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 18),
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
          colors: [Color(0xFFF8FBFF), Color(0xFFEFF4FF), Color(0xFFF9FAFB)],
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
    fill.color = const Color(0xFFBFD5FF).withValues(alpha: 0.32);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.08), 120, fill);
    fill.color = const Color(0xFFFFD6C7).withValues(alpha: 0.34);
    canvas.drawCircle(Offset(size.width * 0.02, size.height * 0.24), 100, fill);

    final grid = Paint()
      ..color = const Color(0xFF172033).withValues(alpha: 0.035)
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
