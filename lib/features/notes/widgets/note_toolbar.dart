import 'package:flutter/material.dart';

class NoteToolbar extends StatelessWidget {
  const NoteToolbar({
    super.key,
    required this.onTemplate,
    required this.onAiWrite,
    required this.onChecklist,
    required this.onImage,
    required this.onVoice,
    required this.onMore,
  });

  final VoidCallback onTemplate;
  final VoidCallback onAiWrite;
  final VoidCallback onChecklist;
  final VoidCallback onImage;
  final VoidCallback onVoice;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            _Tool(
              icon: Icons.edit_note_rounded,
              label: '模板',
              onTap: onTemplate,
            ),
            _Tool(
              icon: Icons.auto_awesome_rounded,
              label: 'AI帮写',
              onTap: onAiWrite,
            ),
            _Tool(
              icon: Icons.check_box_rounded,
              label: '清单',
              onTap: onChecklist,
            ),
            _Tool(icon: Icons.image_rounded, label: '图片', onTap: onImage),
            _Tool(icon: Icons.mic_rounded, label: '语音', onTap: onVoice),
            _Tool(icon: Icons.more_horiz_rounded, label: '更多', onTap: onMore),
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21),
              const SizedBox(height: 5),
              FittedBox(
                child: Text(label, style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
