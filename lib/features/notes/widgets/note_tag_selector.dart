import 'package:flutter/material.dart';

import '../../../core/widgets/sticky_tag.dart';

class NoteTagSelector extends StatelessWidget {
  const NoteTagSelector({
    super.key,
    required this.tags,
    required this.selected,
    required this.onChanged,
    required this.onCreate,
  });

  final List<String> tags;
  final String selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选择标签', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final tag in tags)
              StickyTag(
                label: tag,
                selected: tag == selected,
                onTap: () => onChanged(tag),
              ),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: const Text('新建标签'),
              onPressed: onCreate,
            ),
          ],
        ),
      ],
    );
  }
}
