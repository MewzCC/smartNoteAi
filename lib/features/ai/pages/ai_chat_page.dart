import 'package:flutter/material.dart';

import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/app_scaffold.dart';

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      activePath: '/ai',
      child: SafeArea(
        child: Column(
          children: [
            StickyAppBar(title: 'AI 畅写', showBack: true, showSearch: false),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('把零散对话粘贴进 AI 智能页，就可以整理重点和行动项。'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
