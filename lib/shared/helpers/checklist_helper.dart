class ChecklistLine {
  const ChecklistLine({
    required this.text,
    required this.checked,
    required this.lineIndex,
  });

  final String text;
  final bool checked;
  final int lineIndex;
}

final RegExp _inlineReminderPattern = RegExp(
  r'\s+提醒\s+\d{4}/\d{1,2}/\d{1,2}\s+\d{1,2}:\d{2}\s*$',
);

List<ChecklistLine> extractChecklistLines(String content) {
  final lines = content.split('\n');
  final items = <ChecklistLine>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trimLeft();
    if (line.startsWith('☐ ') || line.startsWith('☑ ')) {
      items.add(
        ChecklistLine(
          text: stripInlineReminderText(line.substring(2)).trim(),
          checked: line.startsWith('☑ '),
          lineIndex: index,
        ),
      );
    }
  }
  return items;
}

String stripInlineReminderText(String value) {
  return value.replaceFirst(_inlineReminderPattern, '').trimRight();
}

String stripInlineReminderTextFromContent(String content) {
  return content
      .split('\n')
      .map((line) {
        final leftTrimmed = line.trimLeft();
        if (!leftTrimmed.startsWith('☐ ') && !leftTrimmed.startsWith('☑ ')) {
          return line;
        }
        return stripInlineReminderText(line);
      })
      .join('\n');
}

bool hasChecklistLines(String content) =>
    extractChecklistLines(content).isNotEmpty;

bool areChecklistLinesComplete(String content) {
  final items = extractChecklistLines(content);
  return items.isNotEmpty && items.every((item) => item.checked);
}

bool canCompleteTaskContent(String content) {
  final items = extractChecklistLines(content);
  return items.isEmpty || items.every((item) => item.checked);
}

String toggleChecklistLine(String content, int lineIndex) {
  final lines = content.split('\n');
  if (lineIndex < 0 || lineIndex >= lines.length) return content;
  final line = lines[lineIndex];
  final leftTrimmed = line.trimLeft();
  final indent = line.substring(0, line.length - leftTrimmed.length);
  if (leftTrimmed.startsWith('☐ ')) {
    lines[lineIndex] = '$indent☑ ${leftTrimmed.substring(2).trim()}';
  } else if (leftTrimmed.startsWith('☑ ')) {
    lines[lineIndex] = '$indent☐ ${leftTrimmed.substring(2).trim()}';
  }
  return lines.join('\n');
}

String contentWithoutChecklistLines(String content) {
  return content
      .split('\n')
      .where((line) {
        final value = line.trimLeft();
        return !value.startsWith('☐ ') && !value.startsWith('☑ ');
      })
      .join('\n')
      .trim();
}
