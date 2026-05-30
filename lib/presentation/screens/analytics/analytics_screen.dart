import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/task_model.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final goals = ref.watch(goalsProvider);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final productivityScore = ref.watch(productivityScoreProvider);
    final alignmentScore = ref.watch(goalAlignmentScoreProvider);

    // Calculate stats
    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.done).length;
    final pendingTasks =
        tasks.where((t) => t.status != TaskStatus.done).length;
    final avgGoalProgress = goals.isEmpty
        ? 0.0
        : goals.map((g) => g.progress).fold(0.0, (a, b) => a + b) /
              goals.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.analytics),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Scores Row
          Row(
            children: [
              Expanded(
                child: _ScoreCard(
                  title: l10n.productivity,
                  score: productivityScore,
                  color: AppColors.success,
                  icon: Icons.bolt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScoreCard(
                  title: l10n.goalAlignment,
                  score: alignmentScore,
                  color: AppColors.highlight,
                  icon: Icons.track_changes_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Task Overview
          _SectionCard(
            title: 'Task Overview',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total',
                  value: '${tasks.length}',
                  color: AppColors.info,
                ),
                _StatItem(
                  label: 'Completed',
                  value: '$completedTasks',
                  color: AppColors.success,
                ),
                _StatItem(
                  label: 'Pending',
                  value: '$pendingTasks',
                  color: AppColors.warning,
                ),
                _StatItem(
                  label: 'Goals',
                  value: '${goals.length}',
                  color: AppColors.highlight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Goals Progress
          if (goals.isNotEmpty) ...[
            _SectionCard(
              title: l10n.goalProgress,
              child: Column(
                children: goals
                    .take(5)
                    .map(
                      (g) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _GoalProgressBar(
                          goal: g,
                          locale: locale,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Priority Distribution Chart
          if (tasks.isNotEmpty)
            _SectionCard(
              title: 'Task Priority Distribution',
              child: SizedBox(
                height: 200,
                child: _PriorityChart(tasks: tasks),
              ),
            ),
          const SizedBox(height: 16),

          // Habit Streaks
          if (habits.isNotEmpty) ...[
            _SectionCard(
              title: '${l10n.habits} — ${l10n.streak}',
              child: Column(
                children: habits
                    .take(5)
                    .map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                h.getTitle(locale),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${h.streak}',
                                  style: const TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // AI Prediction
          if (goals.isNotEmpty)
            ...goals.take(3).map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PredictionCard(goal: g, locale: locale),
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;
  final IconData icon;

  const _ScoreCard({
    required this.title,
    required this.score,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 40,
            lineWidth: 6,
            percent: score / 100,
            center: Text(
              '$score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            progressColor: color,
            backgroundColor: AppColors.surface,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _GoalProgressBar extends StatelessWidget {
  final GoalModel goal;
  final String locale;

  const _GoalProgressBar({required this.goal, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                goal.getTitle(locale),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(goal.progress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          lineHeight: 6,
          percent: goal.progress.clamp(0.0, 1.0),
          progressColor: AppColors.highlight,
          backgroundColor: AppColors.surface,
          barRadius: const Radius.circular(3),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _PriorityChart extends StatelessWidget {
  final List<TaskModel> tasks;

  const _PriorityChart({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final counts = <TaskPriority, int>{};
    for (final t in tasks) {
      counts[t.priority] = (counts[t.priority] ?? 0) + 1;
    }

    final sections = <PieChartSectionData>[];
    final colors = [
      AppColors.priorityRed,
      AppColors.priorityOrange,
      AppColors.priorityYellow,
      AppColors.priorityGreen,
      AppColors.priorityGray,
    ];

    for (int i = 0; i < TaskPriority.values.length; i++) {
      final priority = TaskPriority.values[i];
      final count = counts[priority] ?? 0;
      if (count == 0) continue;
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: colors[i],
          radius: 60,
          title: '$count',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Legend(color: AppColors.priorityRed, label: '🔴 High Impact'),
            _Legend(color: AppColors.priorityOrange, label: '🟠 Important'),
            _Legend(color: AppColors.priorityYellow, label: '🟡 Normal'),
            _Legend(color: AppColors.priorityGreen, label: '🟢 Health'),
            _Legend(color: AppColors.priorityGray, label: '⚪ Optional'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final GoalModel goal;
  final String locale;

  const _PredictionCard({required this.goal, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daysToComplete = goal.estimateDaysToComplete();
    final isOnTrack = daysToComplete <= goal.daysRemaining;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOnTrack
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnTrack ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: isOnTrack ? AppColors.success : AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.getTitle(locale),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isOnTrack
                      ? '${l10n.onTrack} $daysToComplete ${l10n.days}'
                      : '⚠️ Behind schedule — needs acceleration',
                  style: TextStyle(
                    color: isOnTrack ? AppColors.success : AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
