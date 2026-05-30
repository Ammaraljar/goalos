import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/time_block_model.dart';
import '../../../data/models/task_model.dart';

class TimeBlockCard extends StatelessWidget {
  final TimeBlockModel block;
  final String locale;
  final VoidCallback? onComplete;

  const TimeBlockCard({
    super.key,
    required this.block,
    required this.locale,
    this.onComplete,
  });

  Color get _priorityColor {
    switch (block.priorityColorIndex) {
      case 0:
        return AppColors.priorityRed;
      case 1:
        return AppColors.priorityOrange;
      case 2:
        return AppColors.priorityYellow;
      case 3:
        return AppColors.priorityGreen;
      default:
        return AppColors.priorityGray;
    }
  }

  bool get _isCurrentBlock {
    final now = DateTime.now();
    final startMinutes = block.startHour * 60 + block.startMinute;
    final endMinutes = block.endHour * 60 + block.endMinute;
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = _isCurrentBlock;
    final color = _priorityColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  block.startTimeFormatted,
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrent
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  width: 1,
                  height: 16,
                  color: AppColors.surface,
                ),
                Text(
                  block.endTimeFormatted,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Block card
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: block.isCompleted
                    ? AppColors.surface
                    : isCurrent
                    ? color.withOpacity(0.15)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: block.isCompleted
                        ? AppColors.textMuted
                        : color,
                    width: 3,
                  ),
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          block.getLabel(locale),
                          style: TextStyle(
                            color: block.isCompleted
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: block.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${block.durationMinutes} min',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent && !block.isCompleted && onComplete != null)
                    GestureDetector(
                      onTap: onComplete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.5)),
                        ),
                        child: Text(
                          '✓',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else if (block.isCompleted)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
