import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 2)
class HabitModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String goalId;

  @HiveField(2)
  late String titleEn;

  @HiveField(3)
  late String titleAr;

  @HiveField(4)
  late bool isDaily; // true = daily, false = weekly

  @HiveField(5)
  late int streak;

  @HiveField(6)
  late List<DateTime> completionDates;

  @HiveField(7)
  late DateTime createdAt;

  HabitModel({
    String? id,
    required this.goalId,
    required this.titleEn,
    required this.titleAr,
    this.isDaily = true,
    this.streak = 0,
    List<DateTime>? completionDates,
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.completionDates = completionDates ?? [];
    this.createdAt = createdAt ?? DateTime.now();
  }

  String getTitle(String locale) => locale == 'ar' ? titleAr : titleEn;

  bool isCompletedToday() {
    final today = DateTime.now();
    return completionDates.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );
  }

  double get completionRate {
    if (completionDates.isEmpty) return 0.0;
    final daysSinceCreation =
        DateTime.now().difference(createdAt).inDays.clamp(1, 9999);
    return (completionDates.length / daysSinceCreation).clamp(0.0, 1.0);
  }

  void markComplete() {
    final today = DateTime.now();
    if (!isCompletedToday()) {
      completionDates.add(today);
      // Calculate streak
      _recalculateStreak();
    }
  }

  void _recalculateStreak() {
    if (completionDates.isEmpty) {
      streak = 0;
      return;
    }
    final sortedDates = completionDates.toList()
      ..sort((a, b) => b.compareTo(a));

    int currentStreak = 1;
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final diff = sortedDates[i].difference(sortedDates[i + 1]).inDays;
      if (diff == 1) {
        currentStreak++;
      } else {
        break;
      }
    }
    streak = currentStreak;
  }

  HabitModel copyWith({
    String? goalId,
    String? titleEn,
    String? titleAr,
    bool? isDaily,
  }) {
    return HabitModel(
      id: id,
      goalId: goalId ?? this.goalId,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      isDaily: isDaily ?? this.isDaily,
      streak: streak,
      completionDates: completionDates,
      createdAt: createdAt,
    );
  }
}
