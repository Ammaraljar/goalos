import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_model.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final String goalId;
  final TaskModel? existingTask;

  const TaskFormScreen({super.key, required this.goalId, this.existingTask});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _titleArCtrl;
  late final TextEditingController _durationCtrl;
  late TaskPriority _priority;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleEnCtrl = TextEditingController(text: t?.titleEn ?? '');
    _titleArCtrl = TextEditingController(text: t?.titleAr ?? '');
    _durationCtrl =
        TextEditingController(text: t?.durationMinutes.toString() ?? '30');
    _priority = t?.priority ?? TaskPriority.yellow;
    _status = t?.status ?? TaskStatus.todo;
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final task = TaskModel(
      id: widget.existingTask?.id,
      goalId: widget.goalId,
      titleEn: _titleEnCtrl.text.trim(),
      titleAr: _titleArCtrl.text.trim(),
      durationMinutes: int.tryParse(_durationCtrl.text) ?? 30,
      priority: _priority,
      status: _status,
    );

    if (widget.existingTask != null) {
      await ref.read(tasksProvider.notifier).updateTask(task);
    } else {
      await ref.read(tasksProvider.notifier).addTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existingTask != null ? l10n.editTask : l10n.addTask,
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              l10n.save,
              style: const TextStyle(
                color: AppColors.highlight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleEnCtrl,
              decoration: InputDecoration(labelText: l10n.titleEn),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleArCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(labelText: l10n.titleAr),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.duration),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0 ? 'Enter valid duration' : null;
              },
            ),
            const SizedBox(height: 20),

            // Priority Color Selector
            Text(
              l10n.priorityColor,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...TaskPriority.values.map((p) {
              final color = _getColor(p);
              final label = _getLabel(p, l10n);
              return GestureDetector(
                onTap: () => setState(() => _priority = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _priority == p
                        ? color.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _priority == p
                          ? color
                          : AppColors.textMuted.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          color: _priority == p
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: _priority == p
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_priority == p)
                        Icon(
                          Icons.check_rounded,
                          color: color,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l10n.save,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(TaskPriority p) {
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

  String _getLabel(TaskPriority p, AppLocalizations l10n) {
    switch (p) {
      case TaskPriority.red:
        return '🔴 ${l10n.highImpact}';
      case TaskPriority.orange:
        return '🟠 ${l10n.important}';
      case TaskPriority.yellow:
        return '🟡 ${l10n.normal}';
      case TaskPriority.green:
        return '🟢 ${l10n.health}';
      case TaskPriority.gray:
        return '⚪ ${l10n.optional}';
    }
  }
}
