import 'package:flutter/material.dart';

import '../../../shared/enums/note_color.dart';

class NoteColorSelector extends StatelessWidget {
  const NoteColorSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final NoteColor selected;
  final ValueChanged<NoteColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PanelBlock(
      title: '选择便签颜色',
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final item in NoteColor.values)
            _ColorDot(
              color: item.color,
              selected: item == selected,
              onTap: () => onChanged(item),
            ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.selected = false, this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? const Color(0xFF5E4A00) : const Color(0xFFEDE2C5),
            width: selected ? 2 : 1,
          ),
        ),
        child: selected ? const Icon(Icons.check_rounded, size: 18) : null,
      ),
    );
  }
}

class _PanelBlock extends StatelessWidget {
  const _PanelBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
