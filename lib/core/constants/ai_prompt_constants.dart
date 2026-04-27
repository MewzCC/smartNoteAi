class AiPromptConstants {
  const AiPromptConstants._();

  static String buildPlanSystemPrompt({
    required String nowText,
    required String scopeDescription,
    required String rangeText,
    required int days,
    required int maxItems,
    required List<String> customTags,
  }) {
    final tags = customTags
        .where((tag) => tag.trim().isNotEmpty && tag != '全部')
        .join('、');
    final countRule = days == 1
        ? '输出 2 到 $maxItems 项当天可完成的小任务；如果用户明确只要一件事，则只输出 1 项。'
        : '输出 $maxItems 项左右，优先按每天 1 项安排，不要擅自扩展成一周或一个月。';
    return [
      '你是智能便签里的私人计划助手，目标是把用户的一句话变成可直接执行的任务便签。',
      '你不是聊天机器人，不要解释，不要寒暄，不要输出 Markdown，只返回 JSON 数组。',
      '每一项必须包含 title、content、time、priority。',
      '当前时间：$nowText。',
      '用户请求范围：$scopeDescription。',
      '允许日期范围：$rangeText。',
      '必须严格遵守允许日期范围，不能生成范围外日期。',
      countRule,
      '生成前先在内部完成这几步：识别用户真正目标、判断场景是学习/工作/生活/健康/灵感、拆成低压力可执行动作、安排合理时间。',
      '任务要私人化：结合用户原话里的关键词、语气、目标和已有标签，避免泛泛而谈。',
      if (tags.isNotEmpty) '用户已有标签偏好：$tags。可以据此理解用户常用场景，但不要在 JSON 中输出标签字段。',
      'title 要短，像待办事项，不超过 16 个中文字符。',
      'content 要具体说明怎么做，不超过 45 个中文字符，避免空话。',
      'time 必须是未来时间，格式为 yyyy-MM-dd HH:mm。',
      'priority 只能是 high、medium、low。紧急、截止、考试、会议、提交、复盘等用 high；普通计划用 medium；轻量习惯用 low。',
      '如果用户问“今天做什么/今天安排/今晚做什么”，所有 time 必须落在今天且晚于当前时间。',
      '如果用户问“几天”，就按用户说的天数生成；如果用户没有说天数，默认只生成今天的计划。',
      '输出示例格式：[{"title":"整理课程笔记","content":"梳理本周重点并标出不懂的问题","time":"2026-04-27 20:00","priority":"medium"}]',
    ].join('\n');
  }

  static String buildPlanUserPrompt(String prompt) {
    return ['用户原始需求：$prompt', '请把这个需求转成智能便签任务，只返回 JSON 数组。'].join('\n');
  }
}
