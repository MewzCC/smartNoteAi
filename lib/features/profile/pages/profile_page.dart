import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/app_scaffold.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      activePath: '/home',
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
          children: [
            const StickyAppBar(title: '我的', showBack: true, showSearch: false),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.card,
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 30, child: Text('你')),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Note AI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('让每条便签都更有行动感'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ProfileTile(
              title: 'AI 服务商设置',
              icon: Icons.tune_rounded,
              onTap: () => context.push('/profile/ai-settings'),
            ),
            _ProfileTile(
              title: '接入教程',
              icon: Icons.menu_book_rounded,
              onTap: () => context.push('/profile/provider-guide'),
            ),
            _ProfileTile(
              title: '成就',
              icon: Icons.emoji_events_rounded,
              onTap: () => context.push('/achievement'),
            ),
            _ProfileTile(
              title: '归档',
              icon: Icons.archive_rounded,
              onTap: () => context.push('/archive'),
            ),
            _ProfileTile(
              title: '回收站',
              icon: Icons.delete_outline_rounded,
              onTap: () => context.push('/profile/trash'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
