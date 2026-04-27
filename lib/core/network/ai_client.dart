import 'dart:convert';

import '../../data/models/user_config_model.dart';
import '../../shared/enums/note_priority.dart';
import 'dio_client.dart';

class GeneratedPlan {
  const GeneratedPlan({
    required this.title,
    required this.content,
    this.reminderAt,
    this.priority = NotePriority.medium,
  });

  final String title;
  final String content;
  final DateTime? reminderAt;
  final NotePriority priority;

  GeneratedPlan copyWith({
    String? title,
    String? content,
    DateTime? reminderAt,
    NotePriority? priority,
  }) {
    return GeneratedPlan(
      title: title?.isEmpty == true ? this.title : title ?? this.title,
      content: content?.isEmpty == true
          ? this.content
          : content ?? this.content,
      reminderAt: reminderAt ?? this.reminderAt,
      priority: priority ?? this.priority,
    );
  }
}

class AiClient {
  AiClient(this.config);

  final UserConfigModel config;

  Future<List<GeneratedPlan>> generate(String prompt) async {
    if (config.apiKey.trim().isEmpty) {
      throw Exception('请先配置 AI 服务商');
    }

    final response = await DioClient(config).dio.post<Map<String, dynamic>>(
      '/chat/completions',
      data: {
        'model': config.model,
        'temperature': 0.35,
        'messages': [
          {
            'role': 'system',
            'content':
                '你是 AI 智能便签助手。只返回 JSON 数组，每项包含 title、content、time、priority。time 必须是未来时间，格式为 yyyy-MM-dd HH:mm；priority 只能是 high、medium、low。',
          },
          {'role': 'user', 'content': prompt},
        ],
      },
    );
    final content = response.data?['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('AI 服务未返回有效内容');
    }
    return _parse(content, prompt);
  }

  List<GeneratedPlan> _parse(String raw, String fallbackPrompt) {
    final clean = raw
        .replaceAll(RegExp(r'```json|```', caseSensitive: false), '')
        .trim();
    try {
      final decoded = jsonDecode(clean) as List<dynamic>;
      return decoded.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final map = item as Map<String, dynamic>;
        return GeneratedPlan(
          title: map['title'] as String? ?? '智能便签',
          content: map['content'] as String? ?? fallbackPrompt,
          reminderAt:
              _parseFutureTime(map['time'] as String?) ??
              _defaultFutureTime(index),
          priority: NotePriority.values.firstWhere(
            (priority) => priority.name == map['priority'],
            orElse: () => NotePriority.medium,
          ),
        );
      }).toList();
    } catch (_) {
      return clean
          .split(RegExp(r'\n+'))
          .where((line) => line.trim().isNotEmpty)
          .take(6)
          .toList()
          .asMap()
          .entries
          .map(
            (line) => GeneratedPlan(
              title: line.value.trim(),
              content: '由 AI 根据「$fallbackPrompt」生成',
              reminderAt: _defaultFutureTime(line.key),
            ),
          )
          .toList();
    }
  }

  DateTime? _parseFutureTime(String? value) {
    if (value == null) return null;
    final text = value.trim();
    final now = DateTime.now();
    final full = RegExp(
      r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})\s+(\d{1,2}):(\d{2})$',
    ).firstMatch(text);
    if (full != null) {
      final time = DateTime(
        int.parse(full.group(1)!),
        int.parse(full.group(2)!),
        int.parse(full.group(3)!),
        int.parse(full.group(4)!),
        int.parse(full.group(5)!),
      );
      return time.isAfter(now) ? time : null;
    }

    final monthDay = RegExp(
      r'^(\d{1,2})[-/](\d{1,2})\s+(\d{1,2}):(\d{2})$',
    ).firstMatch(text);
    if (monthDay != null) {
      final time = DateTime(
        now.year,
        int.parse(monthDay.group(1)!),
        int.parse(monthDay.group(2)!),
        int.parse(monthDay.group(3)!),
        int.parse(monthDay.group(4)!),
      );
      return time.isAfter(now)
          ? time
          : DateTime(
              now.year + 1,
              int.parse(monthDay.group(1)!),
              int.parse(monthDay.group(2)!),
              int.parse(monthDay.group(3)!),
              int.parse(monthDay.group(4)!),
            );
    }

    final clock = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
    if (clock != null) {
      final time = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(clock.group(1)!),
        int.parse(clock.group(2)!),
      );
      return time.isAfter(now) ? time : time.add(const Duration(days: 1));
    }

    final relative = RegExp(r'^(明天|后天)\s*(\d{1,2}):(\d{2})$').firstMatch(text);
    if (relative != null) {
      final offset = relative.group(1) == '后天' ? 2 : 1;
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: offset));
      return DateTime(
        day.year,
        day.month,
        day.day,
        int.parse(relative.group(2)!),
        int.parse(relative.group(3)!),
      );
    }

    return null;
  }

  DateTime _defaultFutureTime(int index) {
    final now = DateTime.now();
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: index + 1));
    return day.add(Duration(hours: 9 + (index % 4) * 3));
  }
}
