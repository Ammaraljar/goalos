import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_model.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final TaskModel? existingTask;
  final String? preselectedGoalId;

  const TaskFormScreen({super.key, this.existingTask, this.preselectedGoalId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _titleArCtrl;
  late int _duration;
  late TaskPriority _priority;
  late TaskStatus _status;
  late String? _goalId;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _titleEnCtrl = TextEditingController(text: t?.titleEn ?? '');
    _titleArCtrl = TextEditingController(text: t?.titleAr ?? '');
    _duration = t?.durationMinutes ?? 30;
    _priority = t?.priority ?? TaskPriority.yellow;
    _status = t?.status ?? TaskStatus.todo;
    _goalId = t?.goalId ?? widget.preselectedGoalId;
    _scheduledDate = t?.scheduledDate;
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final task = TaskModel(
      id: widget.existingTask?.id,
      goalId: _goalId ?? '',
      titleEn: _titleEnCtrl.text.trim(),
      titleAr: _titleArCtrl.text.trim().isEmpty ? _titleEnCtrl.text.trim() : _titleArCtrl.text.trim(),
      durationMinutes: _duration,
      priority: _priority,
      status: _status,
      scheduledDate: _scheduledDate,
      createdAt: widget.existingTask?.createdAt,
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
    final goals = ref.watch(goalsProvider);
    final locale = ref.watch(localeProvider);

    final priorities = [
      (TaskPriority.red, '🔴 ${l10n.highImpact}', AppColors.priorityRed),
      (TaskPriority.orange, '🟠 ${l10n.important}', AppColors.priorityOrange),
      (TaskPriority.yellow, '🟡 ${l10n.normal}', AppColors.priorityYellow),
      (TaskPriority.green, '🟢 ${l10n.health}', AppColors.priorityGreen),
      (TaskPriority.gray, '⚪ ${l10n.optional}', AppColors.priorityGray),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingTask != null ? l10n.editTask : l10n.addTask),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.save, style: const TextStyle(color: AppColors.highlight, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title EN
            TextFormField(
              controller: _titleEnCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.titleEn,
                filled: true, fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            // Title AR
            TextFormField(
              controller: _titleArCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.titleAr,
                filled: true, fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // Duration
            Text(l10n.duration, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Slider(
                  value: _duration.toDouble(),
                  min: 15, max: 180, divisions: 11,
                  activeColor: AppColors.highlight,
                  inactiveColor: AppColors.surface,
                  onChanged: (v) => setState(() => _duration = v.round()),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Text('$_duration min', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 20),

            // Priority
            Text(l10n.priority, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...priorities.map((p) => GestureDetector(
              onTap: () => setState(() => _priority = p.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _priority == p.$1 ? p.$3.withOpacity(0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _priority == p.$1 ? p.$3 : Colors.transparent, width: 1.5),
                ),
                child: Text(p.$2, style: TextStyle(color: _priority == p.$1 ? p.$3 : AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            )),
            const SizedBox(height: 20),

            // Status
            Text(l10n.status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              _StatusChip(label: l10n.todo, value: TaskStatus.todo, current: _status, onTap: () => setState(() => _status = TaskStatus.todo)),
              const SizedBox(width: 8),
              _StatusChip(label: l10n.inProgress, value: TaskStatus.inProgress, current: _status, onTap: () => setState(() => _status = TaskStatus.inProgress)),
              const SizedBox(width: 8),
              _StatusChip(label: l10n.done, value: TaskStatus.done, current: _status, onTap: () => setState(() => _status = TaskStatus.done)),
            ]),
            const SizedBox(height: 20),

            // Goal Link
            if (goals.isNotEmpty) ...[
              Text(l10n.linkedGoal, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _goalId,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.noLinkedGoal, style: const TextStyle(color: AppColors.textMuted))),
                  ...goals.map((g) => DropdownMenuItem(value: g.id, child: Text(g.getTitle(locale), overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _goalId = v),
              ),
              const SizedBox(height: 20),
            ],

            // Scheduled Date
            Text(l10n.deadline, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _scheduledDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _scheduledDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.highlight, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    _scheduledDate != null ? DateFormat('MMM d, yyyy').format(_scheduledDate!) : 'No date set',
                    style: TextStyle(color: _scheduledDate != null ? AppColors.textPrimary : AppColors.textMuted),
                  ),
                  const Spacer(),
                  if (_scheduledDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _scheduledDate = null),
                      child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.highlight,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l10n.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final TaskStatus value;
  final TaskStatus current;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.highlight.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.highlight : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.highlight : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
