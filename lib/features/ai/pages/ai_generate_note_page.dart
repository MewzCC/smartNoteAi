import 'package:flutter/material.dart';

import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/app_scaffold.dart';

class AiGenerateNotePage extends StatelessWidget {
  const AiGenerateNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      activePath: '/ai',
      child: SafeArea(
        child: Column(
          children: [
            StickyAppBar(title: '生成笔记', showBack: true, showSearch: false),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('在 AI 智能页描述主题，就可以生成便签内容。'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
