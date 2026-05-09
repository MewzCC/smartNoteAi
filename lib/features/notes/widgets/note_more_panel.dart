import 'package:flutter/material.dart';

class NoteMorePanel extends StatelessWidget {
  const NoteMorePanel({
    super.key,
    required this.isPinned,
    required this.isTask,
    required this.done,
    required this.onPinChanged,
    required this.onTaskChanged,
    required this.onDoneChanged,
    required this.onCopy,
    required this.onPreview,
    required this.onArchive,
    required this.onDelete,
    this.doneEnabled = true,
  });

  final bool isPinned;
  final bool isTask;
  final bool done;
  final ValueChanged<bool> onPinChanged;
  final ValueChanged<bool> onTaskChanged;
  final ValueChanged<bool> onDoneChanged;
  final VoidCallback onCopy;
  final VoidCallback onPreview;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final bool doneEnabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '更多操作',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: isPinned,
              onChanged: onPinChanged,
              secondary: const Icon(Icons.star_rounded),
              title: const Text('置顶便签'),
              subtitle: const Text('重要便签会靠前显示'),
            ),
            SwitchListTile(
              value: isTask,
              onChanged: onTaskChanged,
              secondary: const Icon(Icons.check_box_rounded),
              title: const Text('加入任务'),
              subtitle: const Text('开启后会出现在任务页'),
            ),
            if (isTask)
              SwitchListTile(
                value: done,
                onChanged: done || doneEnabled ? onDoneChanged : null,
                secondary: const Icon(Icons.task_alt_rounded),
                title: const Text('完成状态'),
                subtitle: Text(doneEnabled ? '标记已完成或未完成' : '完成所有待办后可标记'),
              ),
            const Divider(),
            _Action(icon: Icons.copy_rounded, label: '复制内容', onTap: onCopy),
            _Action(
              icon: Icons.visibility_rounded,
              label: '预览便签',
              onTap: onPreview,
            ),
            _Action(
              icon: Icons.archive_rounded,
              label: '归档便签',
              onTap: onArchive,
            ),
            _Action(
              icon: Icons.delete_outline_rounded,
              label: '删除便签',
              danger: true,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: danger ? Colors.redAccent : null),
      title: Text(
        label,
        style: TextStyle(color: danger ? Colors.redAccent : null),
      ),
      onTap: onTap,
    );
  }
}
