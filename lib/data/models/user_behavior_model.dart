import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

@HiveType(typeId: 6)
class UserBehaviorModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String eventType; // task_completed, task_skipped, task_added, goal_progress

  @HiveField(2)
  late String? relatedId; // task/goal id

  @HiveField(3)
  late int hour; // hour of day when event happened

  @HiveField(4)
  late int dayOfWeek; // 1=Monday

  @HiveField(5)
  late String category; // health, career, etc

  @HiveField(6)
  late DateTime timestamp;

  UserBehaviorModel({
    String? id,
    required this.eventType,
    this.relatedId,
    required this.hour,
    required this.dayOfWeek,
    required this.category,
    DateTime? timestamp,
  }) {
    this.id = id ?? const Uuid().v4();
    this.timestamp = timestamp ?? DateTime.now();
  }
}
