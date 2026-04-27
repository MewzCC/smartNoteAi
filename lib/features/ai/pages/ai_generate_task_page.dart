import 'package:flutter/material.dart';

import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/app_scaffold.dart';

class AiGenerateTaskPage extends StatelessWidget {
  const AiGenerateTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      activePath: '/ai',
      child: SafeArea(
        child: Column(
          children: [
            StickyAppBar(title: '生成任务', showBack: true, showSearch: false),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('在 AI 智能页输入目标，系统会自动拆成可执行任务。'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
