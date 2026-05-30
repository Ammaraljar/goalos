import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
@HiveType(typeId: 0)
class GoalModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String titleEn;

  @HiveField(2)
  late String titleAr;

  @HiveField(3)
  late String descriptionEn;

  @HiveField(4)
  late String descriptionAr;

  @HiveField(5)
  late DateTime deadline;

  @HiveField(6)
  late int priority; // 1-10

  @HiveField(7)
  late double progress; // 0.0 - 1.0

  @HiveField(8)
  late String category; // health, career, finance, learning, relationships, personal

  @HiveField(9)
  late DateTime createdAt;

  @HiveField(10)
  late bool isActive;

  GoalModel({
    String? id,
    required this.titleEn,
    required this.titleAr,
    this.descriptionEn = '',
    this.descriptionAr = '',
    required this.deadline,
    required this.priority,
    this.progress = 0.0,
    required this.category,
    DateTime? createdAt,
    this.isActive = true,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }

  String getTitle(String locale) => locale == 'ar' ? titleAr : titleEn;
  String getDescription(String locale) =>
      locale == 'ar' ? descriptionAr : descriptionEn;

  int get daysRemaining => deadline.difference(DateTime.now()).inDays;

  int estimateDaysToComplete() {
    if (progress <= 0) return daysRemaining;
    final daysSinceCreation =
        DateTime.now().difference(createdAt).inDays.clamp(1, 9999);
    final ratePerDay = progress / daysSinceCreation;
    if (ratePerDay <= 0) return 999;
    return ((1.0 - progress) / ratePerDay).round();
  }

  GoalModel copyWith({
    String? titleEn,
    String? titleAr,
    String? descriptionEn,
    String? descriptionAr,
    DateTime? deadline,
    int? priority,
    double? progress,
    String? category,
    bool? isActive,
  }) {
    return GoalModel(
      id: id,
      titleEn: titleEn ?? this.titleEn,
      titleAr: titleAr ?? this.titleAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      category: category ?? this.category,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
