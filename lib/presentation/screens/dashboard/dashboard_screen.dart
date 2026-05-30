import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/time_block_model.dart';
import '../../widgets/common/priority_badge.dart';
import '../../widgets/dashboard/alignment_score_card.dart';
import '../../widgets/dashboard/time_block_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final todayBlocks = ref.watch(todayBlocksProvider);
    final top3 = ref.watch(top3PrioritiesProvider);
    final alignmentScore = ref.watch(goalAlignmentScoreProvider);
    final productivityScore = ref.watch(productivityScoreProvider);
    final habits = ref.watch(habitsProvider);
    final goals = ref.watch(goalsProvider);
    final tasks = ref.watch(tasksProvider);

    final now = DateTime.now();
    final dateStr = DateFormat(
      locale == 'ar' ? 'EEEE, d MMMM yyyy' : 'EEEE, MMMM d',
      locale,
    ).format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GoalOS',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.highlight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Productivity Score Ring
                    CircularPercentIndicator(
                      radius: 30,
                      lineWidth: 4,
                      percent: productivityScore / 100,
                      center: Text(
                        '$productivityScore',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      progressColor: AppColors.success,
                      backgroundColor: AppColors.surface,
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  ],
                ),
              ),
            ),

            // Generate Schedule Button (if no schedule)
            if (todayBlocks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _GenerateScheduleButton(
                    onGenerate: () => _generateSchedule(ref),
                  ),
                ),
              ),

            // Goal Alignment Score
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: AlignmentScoreCard(score: alignmentScore),
              ),
            ),

            // Top 3 Priorities
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.topPriorities,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (top3.isEmpty)
                      _EmptyState(message: l10n.noTasks)
                    else
                      ...top3.asMap().entries.map(
                        (e) => _PriorityTaskCard(
                          task: e.value,
                          rank: e.key + 1,
                          locale: locale,
                          goalTitle: goals
                              .firstWhere(
                                (g) => g.id == e.value.goalId,
                                orElse: () => goals.first,
                              )
                              .getTitle(locale),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Today's Schedule
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.dailySchedule,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (todayBlocks.isNotEmpty)
                      GestureDetector(
                        onTap: () => _generateSchedule(ref),
                        child: Text(
                          '↻ Regenerate',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.highlight,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (todayBlocks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _EmptyState(message: l10n.noSchedule),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final block = todayBlocks[index];
                      return TimeBlockCard(
                        block: block,
                        locale: locale,
                        onComplete: () => ref
                            .read(timeBlocksProvider.notifier)
                            .markBlockComplete(block.id),
                      );
                    },
                    childCount: todayBlocks.length,
                  ),
                ),
              ),

            // Habit Status
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          color: AppColors.priorityGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.habitStatus,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (habits.isEmpty)
                      _EmptyState(message: l10n.noHabits)
                    else
                      ...habits.take(4).map(
                        (h) => _HabitStatusTile(habit_model: h, locale: locale),
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _generateSchedule(WidgetRef ref) {
    final goals = ref.read(goalsProvider);
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider);

    ref.read(timeBlocksProvider.notifier).generateScheduleForDate(
      DateTime.now(),
      goals,
      tasks,
      habits,
    );
  }
}

class _GenerateScheduleButton extends StatelessWidget {
  final VoidCallback onGenerate;

  const _GenerateScheduleButton({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGenerate,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.highlight, Color(0xFFFF8A65)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.highlight.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'AI Schedule Ready',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to generate your optimized day',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _PriorityTaskCard extends StatelessWidget {
  final TaskModel task;
  final int rank;
  final String locale;
  final String goalTitle;

  const _PriorityTaskCard({
    required this.task,
    required this.rank,
    required this.locale,
    required this.goalTitle,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: priorityColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: priorityColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.getTitle(locale),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  goalTitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${task.durationMinutes}m',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.red:
        return AppColors.priorityRed;
      case TaskPriority.orange:
        return AppColors.priorityOrange;
      case TaskPriority.yellow:
        return AppColors.priorityYellow;
      case TaskPriority.green:
        return AppColors.priorityGreen;
      case TaskPriority.gray:
        return AppColors.priorityGray;
    }
  }
}

class _HabitStatusTile extends StatelessWidget {
  final dynamic habit_model;
  final String locale;

  const _HabitStatusTile({required this.habit_model, required this.locale});

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit_model.isCompletedToday();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color:
                isCompleted ? AppColors.priorityGreen : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              habit_model.getTitle(locale),
              style: TextStyle(
                color: isCompleted
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 14,
                decoration:
                    isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.warning, size: 14),
              const SizedBox(width: 2),
              Text(
                '${habit_model.streak}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
