import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/goal_model.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/scheduling_engine.dart';
import '../../widgets/common/priority_badge.dart';
import '../tasks/task_form_screen.dart';
import 'goal_form_screen.dart';

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final goals = ref.watch(goalsProvider);
    final tasks = ref.watch(tasksProvider);

    final goal = goals.firstWhere((g) => g.id == goalId);
    final goalTasks = tasks.where((t) => t.goalId == goalId).toList();
    final completedTasks =
        goalTasks.where((t) => t.status == TaskStatus.done).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(goal.getTitle(locale)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GoalFormScreen(existingGoal: goal),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(goal.progress * 100).round()}% Complete',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.daysToComplete(
                                      goal.estimateDaysToComplete(),
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircularPercentIndicator(
                              radius: 40,
                              lineWidth: 6,
                              percent: goal.progress.clamp(0.0, 1.0),
                              center: Text(
                                '${(goal.progress * 100).round()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              progressColor: AppColors.highlight,
                              backgroundColor: AppColors.surface,
                              circularStrokeCap: CircularStrokeCap.round,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress slider
                        Text(
                          'Update progress:',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Slider(
                          value: goal.progress,
                          min: 0,
                          max: 1,
                          activeColor: AppColors.highlight,
                          inactiveColor: AppColors.surface,
                          onChanged: (v) => ref
                              .read(goalsProvider.notifier)
                              .updateProgress(goalId, v),
                        ),
                        // Task completion stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatChip(
                              label: 'Tasks',
                              value: '${goalTasks.length}',
                              color: AppColors.info,
                            ),
                            _StatChip(
                              label: 'Done',
                              value: '$completedTasks',
                              color: AppColors.success,
                            ),
                            _StatChip(
                              label: 'Priority',
                              value: '${goal.priority}/10',
                              color: AppColors.highlight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // AI Decompose Button
                  GestureDetector(
                    onTap: () => _autoDecompose(context, ref, goal, locale),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7C4DFF).withOpacity(0.2),
                            const Color(0xFF448AFF).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF7C4DFF).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF7C4DFF),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Goal Decomposition',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Auto-generate tasks from this goal',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF7C4DFF),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tasks Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskFormScreen(goalId: goalId),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.highlight.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.add_rounded,
                                color: AppColors.highlight,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add Task',
                                style: TextStyle(
                                  color: AppColors.highlight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tasks List
          if (goalTasks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    l10n.noTasks,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = goalTasks[index];
                    return _TaskTile(
                      task: task,
                      locale: locale,
                      onStatusChange: (status) => ref
                          .read(tasksProvider.notifier)
                          .updateStatus(task.id, status),
                      onDelete: () =>
                          ref.read(tasksProvider.notifier).deleteTask(task.id),
                    );
                  },
                  childCount: goalTasks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _autoDecompose(
    BuildContext context,
    WidgetRef ref,
    GoalModel goal,
    String locale,
  ) async {
    final suggested = SchedulingEngine.decomposeGoal(goal);
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DecompositionSheet(
        goal: goal,
        suggestions: suggested,
        onAdd: (task) => ref.read(tasksProvider.notifier).addTask(task),
      ),
    );
  }
}

class _DecompositionSheet extends StatelessWidget {
  final GoalModel goal;
  final List<Map<String, dynamic>> suggestions;
  final Function(TaskModel) onAdd;

  const _DecompositionSheet({
    required this.goal,
    required this.suggestions,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Suggested Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Based on your goal category',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...suggestions.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getPriorityColor(s['priority'] as TaskPriority),
                ),
              ),
              title: Text(
                s['titleEn'] as String,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${s['duration']} min',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.highlight,
                ),
                onPressed: () {
                  final task = TaskModel(
                    goalId: goal.id,
                    titleEn: s['titleEn'] as String,
                    titleAr: s['titleAr'] as String,
                    durationMinutes: s['duration'] as int,
                    priority: s['priority'] as TaskPriority,
                    isAutoGenerated: true,
                  );
                  onAdd(task);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added: ${s['titleEn']}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                for (final s in suggestions) {
                  final task = TaskModel(
                    goalId: goal.id,
                    titleEn: s['titleEn'] as String,
                    titleAr: s['titleAr'] as String,
                    durationMinutes: s['duration'] as int,
                    priority: s['priority'] as TaskPriority,
                    isAutoGenerated: true,
                  );
                  onAdd(task);
                }
                Navigator.pop(context);
              },
              child: const Text('Add All Tasks'),
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

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final String locale;
  final Function(TaskStatus) onStatusChange;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.locale,
    required this.onStatusChange,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (task.priority) {
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

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _priorityColor, width: 3)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onStatusChange(
              isDone ? TaskStatus.todo : TaskStatus.done,
            ),
            child: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isDone ? AppColors.success : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.getTitle(locale),
                  style: TextStyle(
                    color: isDone
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${task.durationMinutes} min',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
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
            fontSize: 20,
            fontWeight: FontWeight.w700,
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
