import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class NoteEditorHeader extends StatelessWidget {
  const NoteEditorHeader({
    super.key,
    required this.title,
    required this.onCancel,
    required this.onDone,
    this.showBack = false,
  });

  final String title;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onCancel,
                child: Text(showBack ? '返回' : '取消'),
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.accentText,
                  minimumSize: const Size(56, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
