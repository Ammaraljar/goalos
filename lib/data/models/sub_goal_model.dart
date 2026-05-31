import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

@HiveType(typeId: 5)
class SubGoalModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String parentGoalId;

  @HiveField(2)
  late String titleEn;

  @HiveField(3)
  late String titleAr;

  @HiveField(4)
  late double progress;

  @HiveField(5)
  late DateTime deadline;

  @HiveField(6)
  late bool isCompleted;

  @HiveField(7)
  late DateTime createdAt;

  SubGoalModel({
    String? id,
    required this.parentGoalId,
    required this.titleEn,
    required this.titleAr,
    this.progress = 0.0,
    required this.deadline,
    this.isCompleted = false,
    DateTime? createdAt,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
  }

  String getTitle(String locale) => locale == 'ar' ? titleAr : titleEn;
}
