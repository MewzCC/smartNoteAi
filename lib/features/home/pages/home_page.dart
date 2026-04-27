import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../shared/components/app_scaffold.dart';
import '../provider/home_provider.dart';
import '../widgets/achievement_preview.dart';
import '../widgets/greeting_card.dart';
import '../widgets/quick_record_box.dart';
import '../widgets/sticky_wall_section.dart';
import '../widgets/today_task_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartNoteProvider);
    final notes = state.visibleNotes;
    return AppScaffold(
      activePath: '/home',
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: StickyAppBar(title: '首页')),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: GreetingCard()),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: '快捷记录',
                action: '全部',
                onTap: () => context.push('/notes/new'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: QuickRecordBox(onTap: () => context.push('/notes/new')),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: '今日任务',
                action: '全部任务',
                onTap: () => context.go('/tasks'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: TodayTaskSection(notes: notes)),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: '便签墙',
                action: '全部便签',
                onTap: () => context.go('/notes'),
              ),
            ),
            StickyWallSection(notes: notes),
            SliverToBoxAdapter(child: _AiEntry(onTap: () => context.go('/ai'))),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: '成就徽章',
                action: '全部成就',
                onTap: () => context.push('/achievement'),
              ),
            ),
            SliverToBoxAdapter(
              child: AchievementPreview(
                doneCount: state.doneCount,
                streak: state.currentStreak,
                activeDays: state.activeDays,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 108)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Text(action),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiEntry extends StatelessWidget {
  const _AiEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.notePurple,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 智能助手',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '让 AI 帮你记录、整理和创作',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
