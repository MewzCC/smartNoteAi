import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sticky_app_bar.dart';
import '../../../data/models/note_model.dart';
import '../../../shared/components/app_scaffold.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/enums/note_priority.dart';
import '../provider/calendar_provider.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smartNoteProvider);
    final selected = state.archiveDate;
    final notes = state.notesOnArchiveDate;
    return AppScaffold(
      activePath: '/calendar',
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          children: [
            const StickyAppBar(title: '日历', showSearch: false),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar<NoteModel>(
                locale: 'zh_CN',
                focusedDay: selected,
                firstDay: DateTime(DateTime.now().year - 3),
                lastDay: DateTime(DateTime.now().year + 3),
                selectedDayPredicate: (day) => isSameDay(day, selected),
                onDaySelected: (selectedDay, focusedDay) {
                  ref
                      .read(smartNoteProvider.notifier)
                      .setArchiveDate(selectedDay);
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.notePurple,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '${selected.month}月${selected.day}日',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            if (notes.isEmpty)
              const EmptyState(
                text: '这一天没有事项',
                icon: Icons.event_busy_rounded,
                height: 110,
              )
            else
              for (final note in notes) _EventCard(note: note),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.note});

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: note.priority.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: 58,
        child: Stack(
          children: [
            Positioned.fill(
              right: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.reminderAt == null
                        ? '未设置提醒'
                        : '${note.reminderAt!.hour.toString().padLeft(2, '0')}:${note.reminderAt!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 0,
              top: 3,
              child: Icon(Icons.star_rounded, color: AppColors.accentText),
            ),
          ],
        ),
      ),
    );
  }
}
