import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/goal_model.dart';

class GoalFormScreen extends ConsumerStatefulWidget {
  final GoalModel? existingGoal;

  const GoalFormScreen({super.key, this.existingGoal});

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _titleArCtrl;
  late final TextEditingController _descEnCtrl;
  late final TextEditingController _descArCtrl;

  late DateTime _deadline;
  late int _priority;
  late String _category;

  @override
  void initState() {
    super.initState();
    final g = widget.existingGoal;
    _titleEnCtrl = TextEditingController(text: g?.titleEn ?? '');
    _titleArCtrl = TextEditingController(text: g?.titleAr ?? '');
    _descEnCtrl = TextEditingController(text: g?.descriptionEn ?? '');
    _descArCtrl = TextEditingController(text: g?.descriptionAr ?? '');
    _deadline = g?.deadline ??
        DateTime.now().add(const Duration(days: 90));
    _priority = g?.priority ?? 5;
    _category = g?.category ?? 'personal';
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    _descEnCtrl.dispose();
    _descArCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final goal = GoalModel(
      id: widget.existingGoal?.id,
      titleEn: _titleEnCtrl.text.trim(),
      titleAr: _titleArCtrl.text.trim(),
      descriptionEn: _descEnCtrl.text.trim(),
      descriptionAr: _descArCtrl.text.trim(),
      deadline: _deadline,
      priority: _priority,
      category: _category,
    );

    if (widget.existingGoal != null) {
      await ref.read(goalsProvider.notifier).updateGoal(goal);
    } else {
      await ref.read(goalsProvider.notifier).addGoal(goal);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1825)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.highlight,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.existingGoal != null ? l10n.editGoal : l10n.addGoal,
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
            // Titles
            _SectionLabel('Title'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleEnCtrl,
              decoration: InputDecoration(
                labelText: l10n.titleEn,
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleArCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(labelText: l10n.titleAr),
            ),
            const SizedBox(height: 20),

            // Descriptions
            _SectionLabel('Description'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descEnCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.descriptionEn),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descArCtrl,
              maxLines: 2,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(labelText: l10n.descriptionAr),
            ),
            const SizedBox(height: 20),

            // Category
            _SectionLabel(l10n.category),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.categories.map((cat) {
                final selected = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.highlight.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AppColors.highlight
                            : AppColors.textMuted.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected
                            ? AppColors.highlight
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Priority Slider
            _SectionLabel('${l10n.priority}: $_priority/10'),
            Slider(
              value: _priority.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: AppColors.highlight,
              inactiveColor: AppColors.surface,
              label: '$_priority',
              onChanged: (v) => setState(() => _priority = v.round()),
            ),
            const SizedBox(height: 20),

            // Deadline
            _SectionLabel(l10n.deadline),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.highlight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_deadline),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_deadline.difference(DateTime.now()).inDays} days',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
