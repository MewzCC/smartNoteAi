import 'package:flutter/material.dart';

class NoteChecklistLine {
  const NoteChecklistLine({
    required this.text,
    required this.checked,
    required this.lineIndex,
  });

  final String text;
  final bool checked;
  final int lineIndex;
}

List<NoteChecklistLine> extractChecklistLines(String content) {
  final lines = content.split('\n');
  final items = <NoteChecklistLine>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trimLeft();
    if (line.startsWith('☐ ') || line.startsWith('☑ ')) {
      items.add(
        NoteChecklistLine(
          text: line.substring(2).trim(),
          checked: line.startsWith('☑ '),
          lineIndex: index,
        ),
      );
    }
  }
  return items;
}

bool hasChecklistLines(String content) => extractChecklistLines(content).isNotEmpty;

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

class NoteChecklistContent extends StatelessWidget {
  const NoteChecklistContent({
    super.key,
    required this.content,
    this.onToggle,
    this.textStyle,
  });

  final String content;
  final ValueChanged<int>? onToggle;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final plain = contentWithoutChecklistLines(content);
    final items = extractChecklistLines(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plain.isNotEmpty) ...[
          Text(plain, style: textStyle ?? const TextStyle(height: 1.8)),
          if (items.isNotEmpty) const SizedBox(height: 14),
        ],
        for (final item in items)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onToggle == null ? null : () => onToggle!(item.lineIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 20,
                    color: item.checked
                        ? const Color(0xFF5DBE72)
                        : const Color(0xFF6F6652),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text.isEmpty ? '未命名待办' : item.text,
                      style: (textStyle ?? const TextStyle(height: 1.8))
                          .copyWith(
                            decoration: item.checked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.checked ? Colors.black54 : null,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
