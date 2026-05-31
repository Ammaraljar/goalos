import 'dart:ui' show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/models/goal_model.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final habits = ref.watch(habitsProvider);
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.habits),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.highlight),
            onPressed: () => _showAddHabitSheet(context, ref, goals, locale),
          ),
        ],
      ),
      body: habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.repeat_rounded,
                    size: 64,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noHabits,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final goal = goals.firstWhere(
                  (g) => g.id == habit.goalId,
                  orElse: () => GoalModel(
                    titleEn: 'No goal',
                    titleAr: 'لا يوجد هدف',
                    deadline: DateTime.now(),
                    priority: 1,
                    category: 'personal',
                  ),
                );
                return _HabitCard(
                  habit: habit,
                  locale: locale,
                  goalTitle: goal.getTitle(locale),
                  onToggle: () => ref
                      .read(habitsProvider.notifier)
                      .toggleCompletion(habit.id),
                  onDelete: () =>
                      ref.read(habitsProvider.notifier).deleteHabit(habit.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitSheet(context, ref, goals, locale),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addHabit),
        backgroundColor: AppColors.priorityGreen,
      ),
    );
  }

  void _showAddHabitSheet(
    BuildContext context,
    WidgetRef ref,
    List<GoalModel> goals,
    String locale,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddHabitSheet(
        goals: goals,
        locale: locale,
        onAdd: (habit) => ref.read(habitsProvider.notifier).addHabit(habit),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final String locale;
  final String goalTitle;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.locale,
    required this.goalTitle,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.priorityGreen.withOpacity(0.4)
              : AppColors.surface,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.priorityGreen
                        : Colors.transparent,
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.priorityGreen
                          : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.getTitle(locale),
                      style: TextStyle(
                        color: isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
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
          const SizedBox(height: 14),
          Row(
            children: [
              // Streak
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.warning,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.streak} days',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Completion rate
              Expanded(
                child: Column(
                  children: [
                    LinearPercentIndicator(
                      lineHeight: 6,
                      percent: habit.completionRate,
                      progressColor: AppColors.priorityGreen,
                      backgroundColor: AppColors.surface,
                      barRadius: const Radius.circular(3),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${(habit.completionRate * 100).round()}% rate',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddHabitSheet extends StatefulWidget {
  final List<GoalModel> goals;
  final String locale;
  final Function(HabitModel) onAdd;

  const _AddHabitSheet({
    required this.goals,
    required this.locale,
    required this.onAdd,
  });

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _titleEnCtrl = TextEditingController();
  final _titleArCtrl = TextEditingController();
  bool _isDaily = true;
  String? _selectedGoalId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addHabit,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleEnCtrl,
            decoration: InputDecoration(labelText: l10n.titleEn),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleArCtrl,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(labelText: l10n.titleAr),
          ),
          const SizedBox(height: 16),
          // Daily/Weekly
          Row(
            children: [
              _FreqChip(
                label: l10n.daily,
                selected: _isDaily,
                onTap: () => setState(() => _isDaily = true),
              ),
              const SizedBox(width: 10),
              _FreqChip(
                label: l10n.weekly,
                selected: !_isDaily,
                onTap: () => setState(() => _isDaily = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Goal selector
          if (widget.goals.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedGoalId,
              dropdownColor: AppColors.card,
              decoration: const InputDecoration(labelText: 'Link to goal'),
              items: widget.goals
                  .map(
                    (g) => DropdownMenuItem(
                      value: g.id,
                      child: Text(
                        g.getTitle(widget.locale),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedGoalId = v),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleEnCtrl.text.trim().isEmpty) return;
                final habit = HabitModel(
                  goalId: _selectedGoalId ?? 'none',
                  titleEn: _titleEnCtrl.text.trim(),
                  titleAr:
                      _titleArCtrl.text.trim().isEmpty
                          ? _titleEnCtrl.text.trim()
                          : _titleArCtrl.text.trim(),
                  isDaily: _isDaily,
                );
                widget.onAdd(habit);
                Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreqChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FreqChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.priorityGreen.withOpacity(0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.priorityGreen
                : AppColors.textMuted.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.priorityGreen
                : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
