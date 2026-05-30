import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/scheduling_engine.dart';
import 'goal_form_screen.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.goals),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.highlight),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalFormScreen()),
            ),
          ),
        ],
      ),
      body: goals.isEmpty
          ? _EmptyGoals(l10n: l10n)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _GoalCard(
                  goal: goal,
                  locale: locale,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GoalDetailScreen(goalId: goal.id),
                    ),
                  ),
                  onDelete: () => ref
                      .read(goalsProvider.notifier)
                      .deleteGoal(goal.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoalFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addGoal),
        backgroundColor: AppColors.highlight,
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.locale,
    required this.onTap,
    required this.onDelete,
  });

  Color get _categoryColor {
    final colors = AppColors.categoryColors;
    final cats = AppConstants.categories;
    final idx = cats.indexOf(goal.category);
    return colors[idx >= 0 ? idx % colors.length : 0];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daysLeft = goal.daysRemaining;
    final color = _categoryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    goal.category,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                // Priority dots
                Row(
                  children: List.generate(
                    10,
                    (i) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < goal.priority
                            ? AppColors.highlight
                            : AppColors.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              goal.getTitle(locale),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (goal.getDescription(locale).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                goal.getDescription(locale),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            // Progress bar
            LinearPercentIndicator(
              lineHeight: 6,
              percent: goal.progress.clamp(0.0, 1.0),
              progressColor: color,
              backgroundColor: AppColors.surface,
              barRadius: const Radius.circular(3),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${(goal.progress * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: daysLeft < 30
                      ? AppColors.error
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '$daysLeft days left',
                  style: TextStyle(
                    color: daysLeft < 30
                        ? AppColors.error
                        : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyGoals({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            l10n.noGoals,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
