import 'dart:convert';

import '../constants/ai_prompt_constants.dart';
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
    final scope = _PlanScope.fromPrompt(prompt, DateTime.now());

    final response = await DioClient(config).dio.post<Map<String, dynamic>>(
      '/chat/completions',
      data: {
        'model': config.model,
        'temperature': 0.35,
        'max_tokens': 1800,
        'messages': [
          {
            'role': 'system',
            'content': AiPromptConstants.buildPlanSystemPrompt(
              nowText: scope.nowText,
              scopeDescription: scope.description,
              rangeText: scope.rangeText,
              days: scope.days,
              hasExplicitDayCount: scope.hasExplicitDayCount,
              hasWeeklyPlanIntent: scope.hasWeeklyPlanIntent,
              maxItems: scope.maxItems,
              customTags: config.customTags,
            ),
          },
          {
            'role': 'user',
            'content': AiPromptConstants.buildPlanUserPrompt(prompt),
          },
        ],
      },
    );
    final content = response.data?['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('AI 服务未返回有效内容');
    }
    return _parse(content, prompt, scope);
  }

  List<GeneratedPlan> _parse(
    String raw,
    String fallbackPrompt,
    _PlanScope scope,
  ) {
    final clean = raw
        .replaceAll(RegExp(r'```json|```', caseSensitive: false), '')
        .trim();
    try {
      final decoded = jsonDecode(clean) as List<dynamic>;
      return decoded.take(scope.maxItems).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final map = item as Map<String, dynamic>;
        return GeneratedPlan(
          title: map['title'] as String? ?? '智能便签',
          content: map['content'] as String? ?? fallbackPrompt,
          reminderAt: scope.normalizeTime(
            _parseFutureTime(map['time'] as String?),
            index,
          ),
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
          .take(scope.maxItems)
          .toList()
          .asMap()
          .entries
          .map(
            (line) => GeneratedPlan(
              title: line.value.trim(),
              content: '由 AI 根据「$fallbackPrompt」生成',
              reminderAt: scope.defaultFutureTime(line.key),
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

    final relative = RegExp(
      r'^(今天|明天|后天)\s*(\d{1,2}):(\d{2})$',
    ).firstMatch(text);
    if (relative != null) {
      final offset = switch (relative.group(1)) {
        '后天' => 2,
        '明天' => 1,
        _ => 0,
      };
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
}

class _PlanScope {
  _PlanScope({
    required this.now,
    required this.startDay,
    required this.days,
    required this.hasExplicitDayCount,
    required this.hasWeeklyPlanIntent,
    required this.maxItems,
    required this.description,
  });

  final DateTime now;
  final DateTime startDay;
  final int days;
  final bool hasExplicitDayCount;
  final bool hasWeeklyPlanIntent;
  final int maxItems;
  final String description;

  DateTime get endExclusive => startDay.add(Duration(days: days));

  String get nowText =>
      '${now.year}-${_two(now.month)}-${_two(now.day)} ${_two(now.hour)}:${_two(now.minute)}';

  String get rangeText {
    final endDay = endExclusive.subtract(const Duration(days: 1));
    if (_sameDay(startDay, endDay)) {
      return '${startDay.year}-${_two(startDay.month)}-${_two(startDay.day)}';
    }
    return '${startDay.year}-${_two(startDay.month)}-${_two(startDay.day)} 至 ${endDay.year}-${_two(endDay.month)}-${_two(endDay.day)}';
  }

  factory _PlanScope.fromPrompt(String prompt, DateTime now) {
    final today = _dateOnly(now);
    final compact = prompt.replaceAll(RegExp(r'\s+'), '');
    final dayMatch = RegExp(r'([0-9一二两三四五六七八九十]{1,3})天').firstMatch(compact);
    final requestedDays = dayMatch == null
        ? null
        : _parseDayCount(dayMatch.group(1)!);

    if (compact.contains('后天')) {
      return _PlanScope._single(now, today.add(const Duration(days: 2)), '后天');
    }
    if (compact.contains('明天')) {
      return _PlanScope._single(now, today.add(const Duration(days: 1)), '明天');
    }
    if (_hasTodayWord(compact)) {
      return _PlanScope._single(now, today, '今天');
    }
    if (requestedDays != null) {
      final days = requestedDays.clamp(1, 14);
      return _PlanScope(
        now: now,
        startDay: today,
        days: days,
        hasExplicitDayCount: true,
        hasWeeklyPlanIntent: false,
        maxItems: days == 1 ? 5 : days,
        description: '$days 天计划',
      );
    }
    if (_isWeeklySummaryIntent(compact)) {
      if (compact.contains('下周')) {
        return _PlanScope._single(now, today, '未明确天数（下周总结类，按单条聚合）');
      }
      if (compact.contains('本周') || compact.contains('这周') || compact.contains('周')) {
        return _PlanScope._single(now, today, '未明确天数（本周总结类，按单条聚合）');
      }
    }
    if (_isWeeklyPlanningIntent(compact)) {
      if (compact.contains('下周')) {
        final nextWeekStart = today.add(Duration(days: 8 - today.weekday));
        return _PlanScope(
          now: now,
          startDay: nextWeekStart,
          days: 7,
          hasExplicitDayCount: false,
          hasWeeklyPlanIntent: true,
          maxItems: 7,
          description: '下周计划',
        );
      }
      return _PlanScope(
        now: now,
        startDay: today,
        days: 7,
        hasExplicitDayCount: false,
        hasWeeklyPlanIntent: true,
        maxItems: 7,
        description: compact.contains('本周') || compact.contains('这周') ? '本周计划' : '一周计划',
      );
    }
    return _PlanScope._single(now, today, '今天');
  }

  factory _PlanScope._single(DateTime now, DateTime day, String description) {
    return _PlanScope(
      now: now,
      startDay: _dateOnly(day),
      days: 1,
      hasExplicitDayCount: false,
      hasWeeklyPlanIntent: false,
      maxItems: 1,
      description: description,
    );
  }

  DateTime normalizeTime(DateTime? raw, int index) {
    if (raw == null) return defaultFutureTime(index);
    final targetDay = _targetDay(index);
    final candidate = _contains(raw)
        ? raw
        : DateTime(
            targetDay.year,
            targetDay.month,
            targetDay.day,
            raw.hour,
            raw.minute,
          );
    if (candidate.isAfter(now) && _contains(candidate)) return candidate;
    return defaultFutureTime(index);
  }

  DateTime defaultFutureTime(int index) {
    final targetDay = _targetDay(index);
    final hour = 9 + (index % 4) * 3;
    var time = DateTime(targetDay.year, targetDay.month, targetDay.day, hour);
    if (!time.isAfter(now)) {
      final minutes = 30 + index * 20;
      time = now.add(Duration(minutes: minutes));
      if (!_contains(time)) {
        time = DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 50);
      }
    }
    return time;
  }

  DateTime _targetDay(int index) => startDay.add(Duration(days: index % days));

  bool _contains(DateTime value) {
    final day = _dateOnly(value);
    return !day.isBefore(startDay) && day.isBefore(endExclusive);
  }
}

bool _hasTodayWord(String value) {
  return value.contains('今天') ||
      value.contains('今日') ||
      value.contains('今晚') ||
      value.contains('当天') ||
      value.contains('上午') ||
      value.contains('下午') ||
      value.contains('晚上');
}

bool _isWeeklyPlanningIntent(String value) {
  const planningKeywords = [
    '计划',
    '安排',
    '待办',
    '任务',
    '健身',
    '训练',
    '学习',
    '工作',
    '复习',
    '课程',
  ];
  final hasWeekWord =
      value.contains('周计划') ||
      value.contains('下周') ||
      value.contains('本周') ||
      value.contains('这周') ||
      value.contains('一周') ||
      value.contains('周');
  final hasPlanningKeyword = planningKeywords.any(value.contains);
  return hasWeekWord && hasPlanningKeyword && !_isWeeklySummaryIntent(value);
}

bool _isWeeklySummaryIntent(String value) {
  const summaryKeywords = [
    '总结',
    '归纳',
    '汇总',
    '梳理',
    '回顾',
    '复盘',
    '提炼',
    '记录',
    '概括',
    '整理',
  ];
  final hasWeekWord =
      value.contains('本周') ||
      value.contains('这周') ||
      value.contains('下周') ||
      value.contains('一周') ||
      value.contains('周');
  return hasWeekWord && summaryKeywords.any(value.contains);
}

int? _parseDayCount(String value) {
  final number = int.tryParse(value);
  if (number != null) return number;
  const values = {
    '一': 1,
    '二': 2,
    '两': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
  };
  if (value == '十') return 10;
  if (value.startsWith('十')) {
    return 10 + (values[value.substring(1)] ?? 0);
  }
  if (value.endsWith('十')) {
    return (values[value.substring(0, 1)] ?? 1) * 10;
  }
  if (value.contains('十')) {
    final parts = value.split('十');
    return (values[parts.first] ?? 1) * 10 + (values[parts.last] ?? 0);
  }
  return values[value];
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _two(int value) => value.toString().padLeft(2, '0');
