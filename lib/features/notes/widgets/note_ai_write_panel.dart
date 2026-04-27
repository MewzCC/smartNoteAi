import 'package:flutter/material.dart';

import '../../../core/widgets/sticky_input.dart';

class NoteAiWritePanel extends StatefulWidget {
  const NoteAiWritePanel({
    super.key,
    required this.controller,
    required this.onGenerate,
  });

  final TextEditingController controller;
  final Future<void> Function() onGenerate;

  @override
  State<NoteAiWritePanel> createState() => _NoteAiWritePanelState();
}

class _NoteAiWritePanelState extends State<NoteAiWritePanel> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 帮写',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            StickyInput(controller: widget.controller, hint: '例如：制定今日学习计划'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generating ? null : _generate,
                icon: _generating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_generating ? '生成中...' : '生成内容'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      await widget.onGenerate();
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}
