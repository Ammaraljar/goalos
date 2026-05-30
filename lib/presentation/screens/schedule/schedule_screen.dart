import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/time_block_model.dart';
import '../../widgets/dashboard/time_block_card.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final allBlocks = ref.watch(timeBlocksProvider);
    final selectedBlocks = allBlocks
        .where((b) => b.isForDate(selectedDate))
        .toList()
      ..sort((a, b) {
        final aM = a.startHour * 60 + a.startMinute;
        final bM = b.startHour * 60 + b.startMinute;
        return aM.compareTo(bM);
      });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.schedule),
        backgroundColor: AppColors.background,
        actions: [
          TextButton.icon(
            onPressed: () => _generateForDate(ref, selectedDate),
            icon: const Icon(
              Icons.auto_fix_high_rounded,
              size: 18,
              color: AppColors.highlight,
            ),
            label: Text(
              'Generate',
              style: const TextStyle(color: AppColors.highlight),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            color: AppColors.backgroundLight,
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, selectedDate),
              onDaySelected: (selected, focused) {
                ref.read(selectedDateProvider.notifier).state = selected;
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.highlight,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.highlight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(
                  color: AppColors.textSecondary,
                ),
                defaultTextStyle: const TextStyle(
                  color: AppColors.textPrimary,
                ),
                outsideTextStyle: const TextStyle(
                  color: AppColors.textMuted,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.textSecondary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: AppColors.textSecondary),
                weekendStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),

          // Schedule blocks
          Expanded(
            child: selectedBlocks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noSchedule,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _generateForDate(ref, selectedDate),
                          icon: const Icon(Icons.auto_fix_high_rounded),
                          label: Text(l10n.generateNow),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedBlocks.length,
                    itemBuilder: (context, index) {
                      final block = selectedBlocks[index];
                      return TimeBlockCard(
                        block: block,
                        locale: locale,
                        onComplete: () => ref
                            .read(timeBlocksProvider.notifier)
                            .markBlockComplete(block.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _generateForDate(WidgetRef ref, DateTime date) {
    final goals = ref.read(goalsProvider);
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider);
    ref.read(timeBlocksProvider.notifier).generateScheduleForDate(
      date,
      goals,
      tasks,
      habits,
    );
  }
}
