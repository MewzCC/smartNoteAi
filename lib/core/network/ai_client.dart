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
    this.tag = 'AI',
  });

  final String title;
  final String content;
  final DateTime? reminderAt;
  final NotePriority priority;
  final String tag;

  GeneratedPlan copyWith({
    String? title,
    String? content,
    DateTime? reminderAt,
    NotePriority? priority,
    String? tag,
  }) {
    return GeneratedPlan(
      title: title?.isEmpty == true ? this.title : title ?? this.title,
      content: content?.isEmpty == true
          ? this.content
          : content ?? this.content,
      reminderAt: reminderAt ?? this.reminderAt,
      priority: priority ?? this.priority,
      tag: tag?.isEmpty == true ? this.tag : tag ?? this.tag,
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
        'temperature': 0.42,
        'max_tokens': 2600,
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
              hasMonthlyPlanIntent: scope.hasMonthlyPlanIntent,
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
        final item = entry.value as Map<String, dynamic>;
        final title = (item['title'] as String?)?.trim();
        final content = (item['content'] as String?)?.trim();
        final tag = _normalizeTag(
          item['tag'] as String?,
          '$title $content $fallbackPrompt',
          config.customTags,
        );
        return GeneratedPlan(
          title: title?.isNotEmpty == true ? title! : '智能便签',
          content: content?.isNotEmpty == true ? content! : fallbackPrompt,
          reminderAt: scope.normalizeTime(
            _parseFutureTime(item['time'] as String?),
            index,
          ),
          priority: NotePriority.values.firstWhere(
            (priority) => priority.name == item['priority'],
            orElse: () => _inferPriority('$title $content'),
          ),
          tag: tag,
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
          .map((line) {
            final text = line.value.trim();
            return GeneratedPlan(
              title: text.length > 16 ? text.substring(0, 16) : text,
              content: '围绕“$fallbackPrompt”整理成可执行事项：$text',
              reminderAt: scope.defaultFutureTime(line.key),
              priority: _inferPriority(text),
              tag: _normalizeTag(
                null,
                '$text $fallbackPrompt',
                config.customTags,
              ),
            );
          })
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
      r'^(今天|今晚|明天|后天)\s*(\d{1,2}):(\d{2})$',
    ).firstMatch(text);
    if (relative != null) {
      final offset = switch (relative.group(1)) {
        '后天' => 2,
        '明天' => 1,
        _ => 0,
      };
      final day = _dateOnly(now).add(Duration(days: offset));
      final time = DateTime(
        day.year,
        day.month,
        day.day,
        int.parse(relative.group(2)!),
        int.parse(relative.group(3)!),
      );
      return time.isAfter(now) ? time : null;
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
    required this.hasMonthlyPlanIntent,
    required this.maxItems,
    required this.description,
  });

  final DateTime now;
  final DateTime startDay;
  final int days;
  final bool hasExplicitDayCount;
  final bool hasWeeklyPlanIntent;
  final bool hasMonthlyPlanIntent;
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
    final dayCount = _extractDayCount(compact);
    final weekdayTarget = _extractWeekdayTarget(compact, today);

    if (weekdayTarget != null) {
      return _PlanScope._single(
        now,
        weekdayTarget,
        '指定星期计划',
        explicit: true,
        maxItems: 4,
      );
    }

    if (_hasQuarterIntent(compact)) {
      return _PlanScope(
        now: now,
        startDay: today,
        days: 90,
        hasExplicitDayCount: false,
        hasWeeklyPlanIntent: false,
        hasMonthlyPlanIntent: true,
        maxItems: 10,
        description: '季度阶段计划',
      );
    }

    if (_hasMonthIntent(compact)) {
      final nextMonth = compact.contains('下个月');
      final start = nextMonth ? DateTime(today.year, today.month + 1) : today;
      final end = nextMonth
          ? DateTime(start.year, start.month + 1)
          : DateTime(today.year, today.month + 1);
      final days = end.difference(start).inDays.clamp(1, 31);
      return _PlanScope(
        now: now,
        startDay: start,
        days: days,
        hasExplicitDayCount: false,
        hasWeeklyPlanIntent: false,
        hasMonthlyPlanIntent: true,
        maxItems: 8,
        description: nextMonth ? '下个月计划' : '本月计划',
      );
    }

    if (_hasWorkdayIntent(compact)) {
      final start = today.weekday <= 5
          ? today
          : today.add(Duration(days: 8 - today.weekday));
      final days = (6 - start.weekday).clamp(1, 5);
      return _PlanScope(
        now: now,
        startDay: start,
        days: days,
        hasExplicitDayCount: false,
        hasWeeklyPlanIntent: false,
        hasMonthlyPlanIntent: false,
        maxItems: days,
        description: '工作日计划',
      );
    }

    if (_hasWeekendIntent(compact)) {
      final saturday = today.add(Duration(days: (6 - today.weekday) % 7));
      return _PlanScope(
        now: now,
        startDay: saturday,
        days: 2,
        hasExplicitDayCount: false,
        hasWeeklyPlanIntent: false,
        hasMonthlyPlanIntent: false,
        maxItems: 4,
        description: '周末计划',
      );
    }

    if (_hasTomorrowWord(compact)) {
      return _PlanScope._single(
        now,
        today.add(const Duration(days: 1)),
        '明天计划',
        explicit: true,
        maxItems: 5,
      );
    }
    if (compact.contains('后天')) {
      return _PlanScope._single(
        now,
        today.add(const Duration(days: 2)),
        '后天计划',
        explicit: true,
        maxItems: 5,
      );
    }
    if (_hasTodayWord(compact) || _hasDailyIntent(compact)) {
      return _PlanScope._single(
        now,
        today,
        '今天计划',
        explicit: _hasDailyIntent(compact),
        maxItems: 5,
      );
    }
    if (dayCount != null) {
      final days = dayCount.clamp(1, 14);
      return _PlanScope(
        now: now,
        startDay: today,
        days: days,
        hasExplicitDayCount: true,
        hasWeeklyPlanIntent: false,
        hasMonthlyPlanIntent: false,
        maxItems: days == 1 ? 5 : days.clamp(2, 10),
        description: '$days 天计划',
      );
    }
    if (_isWeeklyPlanningIntent(compact)) {
      final start = compact.contains('下周')
          ? today.add(Duration(days: 8 - today.weekday))
          : today;
      return _PlanScope(
        now: now,
        startDay: start,
        days: 7,
        hasExplicitDayCount: false,
        hasWeeklyPlanIntent: true,
        hasMonthlyPlanIntent: false,
        maxItems: 7,
        description: compact.contains('下周') ? '下周计划' : '本周计划',
      );
    }

    final aggregate = _isAggregateIntent(compact);
    return _PlanScope._single(
      now,
      today,
      aggregate ? '单条聚合便签' : '自然语言默认计划',
      maxItems: aggregate ? 1 : 4,
    );
  }

  factory _PlanScope._single(
    DateTime now,
    DateTime day,
    String description, {
    bool explicit = false,
    int maxItems = 1,
  }) {
    return _PlanScope(
      now: now,
      startDay: _dateOnly(day),
      days: 1,
      hasExplicitDayCount: explicit,
      hasWeeklyPlanIntent: false,
      hasMonthlyPlanIntent: false,
      maxItems: maxItems,
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
    final hours = [9, 14, 18, 20];
    var time = DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
      hours[index % hours.length],
    );
    if (!time.isAfter(now)) {
      time = now.add(Duration(minutes: 30 + index * 20));
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

String _normalizeTag(String? raw, String source, List<String> customTags) {
  final value = raw?.trim();
  final available = <String>{
    '全部',
    '灵感',
    '工作',
    '生活',
    '学习',
    '健康',
    'AI',
    ...customTags.where((tag) => tag.trim().isNotEmpty),
  };
  if (value != null && available.contains(value)) return value;
  for (final tag in customTags) {
    if (tag.trim().isNotEmpty && source.contains(tag)) return tag;
  }
  if (_containsAny(source, [
    '学习',
    '复习',
    '考试',
    '课程',
    '作业',
    'Flutter',
    '编程',
    '代码',
    '阅读',
    '背单词',
  ])) {
    return '学习';
  }
  if (_containsAny(source, [
    '工作',
    '会议',
    '项目',
    '汇报',
    '客户',
    '方案',
    '文档',
    '邮件',
    '需求',
    '迭代',
  ])) {
    return '工作';
  }
  if (_containsAny(source, [
    '运动',
    '健身',
    '训练',
    '跑步',
    '睡眠',
    '饮食',
    '健康',
    '休息',
    '冥想',
  ])) {
    return '健康';
  }
  if (_containsAny(source, [
    '做饭',
    '购物',
    '家务',
    '家庭',
    '出行',
    '整理房间',
    '生活',
    '朋友',
    '约会',
  ])) {
    return '生活';
  }
  if (_containsAny(source, ['灵感', '创意', '想法', '写作', '脑暴', '记录'])) {
    return '灵感';
  }
  return 'AI';
}

NotePriority _inferPriority(String source) {
  if (_containsAny(source, [
    '截止',
    '考试',
    '会议',
    '提交',
    '汇报',
    '紧急',
    '重要',
    '今天必须',
  ])) {
    return NotePriority.high;
  }
  if (_containsAny(source, ['习惯', '散步', '阅读', '整理', '记录', '灵感'])) {
    return NotePriority.low;
  }
  return NotePriority.medium;
}

int? _extractDayCount(String value) {
  final direct = RegExp(r'([0-9]{1,2})[天日]').firstMatch(value);
  if (direct != null) return int.tryParse(direct.group(1)!);
  final chinese = RegExp(r'([一二两三四五六七八九十]{1,3})[天日]').firstMatch(value);
  if (chinese != null) return _parseChineseNumber(chinese.group(1)!);
  final week = RegExp(r'([0-9]{1,2})周').firstMatch(value);
  if (week != null) return (int.tryParse(week.group(1)!) ?? 1) * 7;
  final chineseWeek = RegExp(r'([一二两三四五六七八九十两]{1,3})周').firstMatch(value);
  if (chineseWeek != null) {
    final count = _parseChineseNumber(chineseWeek.group(1)!);
    if (count != null) return count * 7;
  }
  if (_containsAny(value, [
    '这几天',
    '最近几天',
    '未来几天',
    '接下来几天',
    '后面几天',
    '近几天',
    '几天',
  ])) {
    return 3;
  }
  if (_containsAny(value, ['半个月', '两周', '双周', '14天', '十四天'])) {
    return 14;
  }
  if (_containsAny(value, ['一周', '未来一周', '接下来一周', '最近一周', '7天', '七天'])) {
    return 7;
  }
  if (_containsAny(value, ['一个月', '未来30天', '30天', '三十天'])) return 30;
  return null;
}

int? _parseChineseNumber(String value) {
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
  if (value.startsWith('十')) return 10 + (values[value.substring(1)] ?? 0);
  if (value.endsWith('十')) return (values[value.substring(0, 1)] ?? 1) * 10;
  if (value.contains('十')) {
    final parts = value.split('十');
    return (values[parts.first] ?? 1) * 10 + (values[parts.last] ?? 0);
  }
  return values[value];
}

DateTime? _extractWeekdayTarget(String value, DateTime today) {
  final match = RegExp(
    r'(本周|这周|下周|下星期|本星期|这星期|星期|周)([一二三四五六日天1234567])',
  ).firstMatch(value);
  if (match == null) return null;
  final prefix = match.group(1)!;
  final weekday = _parseWeekday(match.group(2)!);
  if (weekday == null) return null;
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final targetWeekStart = prefix.contains('下')
      ? weekStart.add(const Duration(days: 7))
      : prefix == '星期' || prefix == '周'
      ? (weekday < today.weekday
            ? weekStart.add(const Duration(days: 7))
            : weekStart)
      : weekStart;
  var target = targetWeekStart.add(Duration(days: weekday - 1));
  if (target.isBefore(today)) {
    target = target.add(const Duration(days: 7));
  }
  return target;
}

int? _parseWeekday(String value) {
  return switch (value) {
    '一' || '1' => 1,
    '二' || '2' => 2,
    '三' || '3' => 3,
    '四' || '4' => 4,
    '五' || '5' => 5,
    '六' || '6' => 6,
    '日' || '天' || '7' => 7,
    _ => null,
  };
}

bool _hasTodayWord(String value) {
  return _containsAny(value, [
    '今天',
    '今日',
    '今晚',
    '今早',
    '今晨',
    '今下午',
    '今晚上',
    '当天',
    '上午',
    '中午',
    '午后',
    '下午',
    '傍晚',
    '晚上',
    '睡前',
  ]);
}

bool _hasTomorrowWord(String value) => _containsAny(value, ['明天', '明日']);

bool _hasDailyIntent(String value) {
  return _containsAny(value, [
    '日计划',
    '每日计划',
    '一天计划',
    '单日计划',
    '当日计划',
    '今日计划',
    '今日安排',
    '今天安排',
    '明日计划',
    '明天计划',
    '一天能干什么',
  ]);
}

bool _hasWeekendIntent(String value) {
  return _containsAny(value, ['周末', '这周末', '本周末', '这个周末', '下周末', '双休日']);
}

bool _hasMonthIntent(String value) {
  return _containsAny(value, [
    '月计划',
    '本月计划',
    '这个月计划',
    '下个月计划',
    '月度计划',
    '月底前',
    '月末前',
    '月底',
    '月末',
    '月初',
    '月中',
    '本月安排',
    '下月安排',
  ]);
}

bool _hasQuarterIntent(String value) {
  return _containsAny(value, [
    '季度计划',
    '本季度计划',
    '下季度计划',
    '三个月计划',
    '未来三个月',
    '90天计划',
    '九十天计划',
    '长期计划',
    '阶段计划',
  ]);
}

bool _hasWorkdayIntent(String value) {
  return _containsAny(value, [
    '工作日计划',
    '工作日安排',
    '上班日计划',
    '上班日安排',
    '周一到周五',
    '星期一到星期五',
    '本周工作日',
    '下周工作日',
  ]);
}

bool _isWeeklyPlanningIntent(String value) {
  final hasWeekWord = _containsAny(value, [
    '周计划',
    '本周计划',
    '这周计划',
    '下周计划',
    '一周计划',
    '本周安排',
    '这周安排',
    '下周安排',
    '周学习计划',
    '周健身计划',
    '周训练计划',
    '周安排',
    '本周',
    '这周',
    '下周',
    '未来一周',
    '接下来一周',
  ]);
  final hasPlanningWord = _containsAny(value, [
    '计划',
    '安排',
    '待办',
    '任务',
    '能干什么',
    '做什么',
    '学习',
    '工作',
    '健身',
    '训练',
    '复习',
    '冲刺',
  ]);
  return hasWeekWord && hasPlanningWord && !_isAggregateIntent(value);
}

bool _isAggregateIntent(String value) {
  return _containsAny(value, [
    '总结',
    '归纳',
    '汇总',
    '梳理',
    '回顾',
    '复盘',
    '提炼',
    '记录',
    '概括',
    '整理重点',
    '会议重点',
  ]);
}

bool _containsAny(String value, List<String> keywords) {
  return keywords.any(value.contains);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _two(int value) => value.toString().padLeft(2, '0');
