import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'time_block_model.g.dart';

@HiveType(typeId: 3)
class TimeBlockModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String? taskId;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late int startHour;

  @HiveField(4)
  late int startMinute;

  @HiveField(5)
  late int endHour;

  @HiveField(6)
  late int endMinute;

  @HiveField(7)
  late int priorityColorIndex; // TaskPriority index

  @HiveField(8)
  late String labelEn;

  @HiveField(9)
  late String labelAr;

  @HiveField(10)
  late bool isCompleted;

  TimeBlockModel({
    String? id,
    this.taskId,
    required this.date,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.priorityColorIndex,
    required this.labelEn,
    required this.labelAr,
    this.isCompleted = false,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  String getLabel(String locale) => locale == 'ar' ? labelAr : labelEn;

  int get durationMinutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);

  String get startTimeFormatted =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  String get endTimeFormatted =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  bool isForDate(DateTime d) =>
      date.year == d.year && date.month == d.month && date.day == d.day;
}
