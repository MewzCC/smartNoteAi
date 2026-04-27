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
            const Text(
              '清单',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('插入清单模板'),
              subtitle: const Text('适合待办、购物、复盘等便签'),
              onTap: onInsertChecklist,
            ),
            ListTile(
              leading: const Icon(Icons.add_task_rounded),
              title: const Text('添加待办项'),
              subtitle: const Text('在当前内容末尾追加一个待办'),
              onTap: onAppendTodo,
            ),
          ],
        ),
      ),
    );
  }
}
