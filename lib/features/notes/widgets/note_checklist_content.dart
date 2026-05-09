import 'package:flutter/material.dart';

import '../../../shared/helpers/checklist_helper.dart';

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    item.checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 22,
                    color: item.checked
                        ? const Color(0xFF5DBE72)
                        : const Color(0xFF6F6652),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.text.isEmpty ? '未命名待办' : item.text,
                      style: (textStyle ?? const TextStyle(height: 1.8))
                          .copyWith(
                            height: 1.45,
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
