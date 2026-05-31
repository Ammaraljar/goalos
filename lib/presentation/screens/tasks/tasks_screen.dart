import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/goal_model.dart';
import 'task_form_screen.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final goals = ref.watch(goalsProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    final goalMap = {for (var g in goals) g.id: g};
    final pending = tasks.where((t) => t.status != TaskStatus.done).toList();
    final done = tasks.where((t) => t.status == TaskStatus.done).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tasks),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.highlight),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TaskFormScreen())),
          ),
        ],
      ),
      body: tasks.isEmpty
          ? _EmptyState(l10n: l10n)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  _SectionHeader('${l10n.todo} (${pending.length})'),
                  const SizedBox(height: 8),
                  ...pending.map((t) => _TaskCard(
                    task: t,
                    goal: goalMap[t.goalId],
                    locale: locale,
                    onEdit: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: t))),
                    onDelete: () => _confirmDelete(context, ref, t),
                    onStatusChange: (s) => ref.read(tasksProvider.notifier).updateStatus(t.id, s),
                  )),
                ],
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader('${l10n.done} (${done.length})'),
                  const SizedBox(height: 8),
                  ...done.map((t) => _TaskCard(
                    task: t,
                    goal: goalMap[t.goalId],
                    locale: locale,
                    onEdit: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: t))),
                    onDelete: () => _confirmDelete(context, ref, t),
                    onStatusChange: (s) => ref.read(tasksProvider.notifier).updateStatus(t.id, s),
                  )),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const TaskFormScreen())),
        backgroundColor: AppColors.highlight,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addTask),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Task', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${task.titleEn}"?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(tasksProvider.notifier).deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final GoalModel? goal;
  final String locale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(TaskStatus) onStatusChange;

  const _TaskCard({
    required this.task, required this.goal, required this.locale,
    required this.onEdit, required this.onDelete, required this.onStatusChange,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.red: return AppColors.priorityRed;
      case TaskPriority.orange: return AppColors.priorityOrange;
      case TaskPriority.yellow: return AppColors.priorityYellow;
      case TaskPriority.green: return AppColors.priorityGreen;
      case TaskPriority.gray: return AppColors.priorityGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _priorityColor, width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () {
            if (task.status == TaskStatus.todo) onStatusChange(TaskStatus.inProgress);
            else if (task.status == TaskStatus.inProgress) onStatusChange(TaskStatus.done);
            else onStatusChange(TaskStatus.todo);
          },
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? AppColors.success : Colors.transparent,
              border: Border.all(color: isDone ? AppColors.success : AppColors.textMuted, width: 2),
            ),
            child: isDone ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
        ),
        title: Text(
          task.getTitle(locale),
          style: TextStyle(
            color: isDone ? AppColors.textMuted : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.timer_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${task.durationMinutes} min', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              if (goal != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.flag_outlined, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Flexible(child: Text(goal!.getTitle(locale),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
              ],
            ]),
            if (task.scheduledDate != null) ...[
              const SizedBox(height: 2),
              Text(DateFormat('MMM d').format(task.scheduledDate!),
                style: const TextStyle(color: AppColors.info, fontSize: 11)),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.card,
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
          onSelected: (v) {
            if (v == 'edit') onEdit();
            else if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppColors.textPrimary))),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600));
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.task_alt_rounded, size: 64, color: AppColors.textMuted),
      const SizedBox(height: 16),
      Text(l10n.noTasks, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
    ]),
  );
}
