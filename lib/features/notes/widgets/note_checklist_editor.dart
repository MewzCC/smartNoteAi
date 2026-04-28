import 'package:flutter/material.dart';

class NoteChecklistEditor extends StatelessWidget {
  const NoteChecklistEditor({
    super.key,
    required this.onInsertChecklist,
    required this.onAppendTodo,
  });

  final VoidCallback onInsertChecklist;
  final VoidCallback onAppendTodo;

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
                '清单',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('插入清单模板'),
              subtitle: const Text('自动添加三条可勾选待办事项'),
              onTap: onInsertChecklist,
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.add_task_rounded),
              title: const Text('添加待办项'),
              subtitle: const Text('追加一条可勾选待办，并自动加入任务页'),
              onTap: onAppendTodo,
            ),
          ],
        ),
      ),
    );
  }
}
