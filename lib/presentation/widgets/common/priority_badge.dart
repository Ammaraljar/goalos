import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/task_model.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool showLabel;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  Color get color {
    switch (priority) {
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

  String getLabel(AppLocalizations l10n) {
    switch (priority) {
      case TaskPriority.red:
        return l10n.highImpact;
      case TaskPriority.orange:
        return l10n.important;
      case TaskPriority.yellow:
        return l10n.normal;
      case TaskPriority.green:
        return l10n.health;
      case TaskPriority.gray:
        return l10n.optional;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              getLabel(l10n),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
