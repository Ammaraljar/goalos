import '../models/goal_model.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/time_block_model.dart';
import '../../core/theme/app_theme.dart';

/// GoalOS AI Scheduling Engine
/// A rule-based intelligent scheduling system that simulates AI behavior.
/// Converts goals into optimized daily time-blocked schedules.
class SchedulingEngine {
  static const int _workdayStartHour = 6;
  static const int _workdayEndHour = 22;

  /// Generate an optimized daily schedule from goals, tasks, and habits
  static List<TimeBlockModel> generateDailySchedule({
    required DateTime date,
    required List<GoalModel> activeGoals,
    required List<TaskModel> pendingTasks,
    required List<HabitModel> habits,
  }) {
    final blocks = <TimeBlockModel>[];

    // Step 1: Add fixed blocks (morning routine, meals)
    blocks.addAll(_generateFixedBlocks(date));

    // Step 2: Score and sort tasks using priority algorithm
    final scoredTasks = _scoreTasks(pendingTasks, activeGoals);

    // Step 3: Find available time slots
    final availableSlots = _findAvailableSlots(blocks, date);

    // Step 4: Assign tasks to energy-matched time slots
    _assignTasksToSlots(scoredTasks, availableSlots, blocks, date);

    // Step 5: Insert habit blocks
    _insertHabitBlocks(habits, blocks, date);

    // Step 6: Sort by start time
    blocks.sort((a, b) {
      final aMinutes = a.startHour * 60 + a.startMinute;
      final bMinutes = b.startHour * 60 + b.startMinute;
      return aMinutes.compareTo(bMinutes);
    });

    return blocks;
  }

  /// Score tasks based on priority, deadline urgency, and goal importance
  static List<_ScoredTask> _scoreTasks(
    List<TaskModel> tasks,
    List<GoalModel> goals,
  ) {
    final goalMap = {for (var g in goals) g.id: g};

    return tasks.map((task) {
      double score = 0;

      // Priority color score (0-40 points)
      switch (task.priority) {
        case TaskPriority.red:
          score += 40;
          break;
        case TaskPriority.orange:
          score += 30;
          break;
        case TaskPriority.yellow:
          score += 20;
          break;
        case TaskPriority.green:
          score += 15;
          break;
        case TaskPriority.gray:
          score += 5;
          break;
      }

      // Goal importance score (0-30 points)
      final goal = goalMap[task.goalId];
      if (goal != null) {
        score += goal.priority * 3; // max 30 points

        // Deadline urgency (0-30 points)
        final daysLeft = goal.daysRemaining;
        if (daysLeft <= 7) {
          score += 30;
        } else if (daysLeft <= 30) {
          score += 20;
        } else if (daysLeft <= 90) {
          score += 10;
        } else {
          score += 5;
        }
      }

      return _ScoredTask(task: task, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  /// Fixed blocks that are always in the schedule
  static List<TimeBlockModel> _generateFixedBlocks(DateTime date) {
    return [
      TimeBlockModel(
        date: date,
        startHour: 6,
        startMinute: 0,
        endHour: 7,
        endMinute: 0,
        priorityColorIndex: TaskPriority.green.index,
        labelEn: 'Morning Routine',
        labelAr: 'الروتين الصباحي',
      ),
      TimeBlockModel(
        date: date,
        startHour: 12,
        startMinute: 0,
        endHour: 13,
        endMinute: 0,
        priorityColorIndex: TaskPriority.green.index,
        labelEn: 'Lunch Break',
        labelAr: 'استراحة الغداء',
      ),
      TimeBlockModel(
        date: date,
        startHour: 21,
        startMinute: 0,
        endHour: 22,
        endMinute: 0,
        priorityColorIndex: TaskPriority.green.index,
        labelEn: 'Evening Reflection',
        labelAr: 'المراجعة المسائية',
      ),
    ];
  }

  /// Find available time slots not occupied by existing blocks
  static List<_TimeSlot> _findAvailableSlots(
    List<TimeBlockModel> existingBlocks,
    DateTime date,
  ) {
    final slots = <_TimeSlot>[];
    final occupied = <_TimeRange>[];

    for (final block in existingBlocks) {
      occupied.add(
        _TimeRange(
          startMinutes: block.startHour * 60 + block.startMinute,
          endMinutes: block.endHour * 60 + block.endMinute,
        ),
      );
    }

    occupied.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    int cursor = _workdayStartHour * 60;
    final workdayEnd = _workdayEndHour * 60;

    for (final range in occupied) {
      if (range.startMinutes > cursor) {
        final slotStart = cursor;
        final slotEnd = range.startMinutes;
        final energyZone = _getEnergyZone(slotStart ~/ 60);
        slots.add(
          _TimeSlot(
            startMinutes: slotStart,
            endMinutes: slotEnd,
            energyZone: energyZone,
          ),
        );
      }
      cursor = range.endMinutes > cursor ? range.endMinutes : cursor;
    }

    if (cursor < workdayEnd) {
      final energyZone = _getEnergyZone(cursor ~/ 60);
      slots.add(
        _TimeSlot(
          startMinutes: cursor,
          endMinutes: workdayEnd,
          energyZone: energyZone,
        ),
      );
    }

    return slots;
  }

  /// Determine energy zone based on hour of day
  static _EnergyZone _getEnergyZone(int hour) {
    if (hour >= 7 && hour < 12) return _EnergyZone.deepWork;
    if (hour >= 12 && hour < 15) return _EnergyZone.learning;
    if (hour >= 15 && hour < 18) return _EnergyZone.medium;
    return _EnergyZone.light;
  }

  /// Match tasks to energy zones and assign to time slots
  static void _assignTasksToSlots(
    List<_ScoredTask> scoredTasks,
    List<_TimeSlot> availableSlots,
    List<TimeBlockModel> blocks,
    DateTime date,
  ) {
    // Group tasks by energy zone preference
    final deepWorkTasks =
        scoredTasks.where((t) => t.task.priority == TaskPriority.red).toList();
    final learningTasks = scoredTasks
        .where(
          (t) =>
              t.task.priority == TaskPriority.orange ||
              t.task.priority == TaskPriority.yellow,
        )
        .toList();
    final lightTasks = scoredTasks
        .where(
          (t) =>
              t.task.priority == TaskPriority.green ||
              t.task.priority == TaskPriority.gray,
        )
        .toList();

    for (final slot in availableSlots) {
      int cursor = slot.startMinutes;

      List<_ScoredTask> preferredTasks;
      switch (slot.energyZone) {
        case _EnergyZone.deepWork:
          preferredTasks = [...deepWorkTasks, ...learningTasks, ...lightTasks];
          break;
        case _EnergyZone.learning:
          preferredTasks = [...learningTasks, ...deepWorkTasks, ...lightTasks];
          break;
        case _EnergyZone.medium:
          preferredTasks = [...learningTasks, ...lightTasks, ...deepWorkTasks];
          break;
        case _EnergyZone.light:
          preferredTasks = [...lightTasks, ...learningTasks, ...deepWorkTasks];
          break;
      }

      for (final scoredTask in preferredTasks) {
        if (scoredTask.assigned) continue;
        final taskEndMinutes = cursor + scoredTask.task.durationMinutes;

        if (taskEndMinutes <= slot.endMinutes) {
          // Add buffer (5 min) between tasks
          final blockEnd = taskEndMinutes;

          blocks.add(
            TimeBlockModel(
              taskId: scoredTask.task.id,
              date: date,
              startHour: cursor ~/ 60,
              startMinute: cursor % 60,
              endHour: blockEnd ~/ 60,
              endMinute: blockEnd % 60,
              priorityColorIndex: scoredTask.task.priorityIndex,
              labelEn: scoredTask.task.titleEn,
              labelAr: scoredTask.task.titleAr,
            ),
          );

          scoredTask.assigned = true;
          cursor = taskEndMinutes + 5; // 5-minute buffer

          // Prevent going past slot end
          if (cursor >= slot.endMinutes) break;
        }
      }
    }
  }

  /// Insert habit blocks into available evening slots
  static void _insertHabitBlocks(
    List<HabitModel> habits,
    List<TimeBlockModel> blocks,
    DateTime date,
  ) {
    // Morning habits at 7:00
    final morningHabits = habits.where((h) => h.isDaily).take(2).toList();
    int morningCursor = 7 * 60; // 7:00

    for (final habit in morningHabits) {
      // Check no overlap
      if (!_hasOverlap(blocks, morningCursor, morningCursor + 20)) {
        blocks.add(
          TimeBlockModel(
            taskId: habit.id,
            date: date,
            startHour: morningCursor ~/ 60,
            startMinute: morningCursor % 60,
            endHour: (morningCursor + 20) ~/ 60,
            endMinute: (morningCursor + 20) % 60,
            priorityColorIndex: TaskPriority.green.index,
            labelEn: habit.titleEn,
            labelAr: habit.titleAr,
          ),
        );
        morningCursor += 25;
      }
    }
  }

  static bool _hasOverlap(
    List<TimeBlockModel> blocks,
    int startMinutes,
    int endMinutes,
  ) {
    for (final block in blocks) {
      final bStart = block.startHour * 60 + block.startMinute;
      final bEnd = block.endHour * 60 + block.endMinute;
      if (startMinutes < bEnd && endMinutes > bStart) return true;
    }
    return false;
  }

  /// Calculate goal alignment score (% of work hours linked to goals)
  static int calculateAlignmentScore(
    List<TimeBlockModel> blocks,
    List<TaskModel> tasks,
  ) {
    if (blocks.isEmpty) return 0;

    final taskIds = {for (var t in tasks) t.id};
    int goalMinutes = 0;
    int totalMinutes = 0;

    for (final block in blocks) {
      final duration = block.durationMinutes;
      totalMinutes += duration;
      if (block.taskId != null && taskIds.contains(block.taskId)) {
        goalMinutes += duration;
      }
    }

    if (totalMinutes == 0) return 0;
    return ((goalMinutes / totalMinutes) * 100).round();
  }

  /// Reschedule missed tasks to next available slots
  static List<TimeBlockModel> rescheduleMissedTasks({
    required List<TimeBlockModel> todayBlocks,
    required DateTime tomorrow,
    required List<TaskModel> allTasks,
    required List<GoalModel> goals,
    required List<HabitModel> habits,
  }) {
    // Find missed high-priority tasks
    final missedTaskIds = todayBlocks
        .where((b) => !b.isCompleted && b.taskId != null)
        .map((b) => b.taskId!)
        .toSet();

    final missedTasks = allTasks
        .where(
          (t) =>
              missedTaskIds.contains(t.id) && t.priority != TaskPriority.gray,
        )
        .toList();

    // Generate tomorrow's schedule with missed tasks at higher priority
    return generateDailySchedule(
      date: tomorrow,
      activeGoals: goals,
      pendingTasks: missedTasks,
      habits: habits,
    );
  }

  /// Decompose a goal into suggested tasks
  static List<Map<String, dynamic>> decomposeGoal(GoalModel goal) {
    final tasks = <Map<String, dynamic>>[];
    final daysLeft = goal.daysRemaining.clamp(1, 9999);

    // Based on category, suggest relevant tasks
    switch (goal.category) {
      case 'health':
        tasks.addAll([
          {
            'titleEn': 'Workout Session',
            'titleAr': 'جلسة تمرين',
            'duration': 60,
            'priority': TaskPriority.green,
          },
          {
            'titleEn': 'Meal Prep',
            'titleAr': 'تحضير الوجبات',
            'duration': 30,
            'priority': TaskPriority.green,
          },
          {
            'titleEn': 'Health Research',
            'titleAr': 'بحث صحي',
            'duration': 30,
            'priority': TaskPriority.yellow,
          },
        ]);
        break;
      case 'career':
        tasks.addAll([
          {
            'titleEn': 'Deep Work Session',
            'titleAr': 'جلسة عمل معمقة',
            'duration': 90,
            'priority': TaskPriority.red,
          },
          {
            'titleEn': 'Skill Development',
            'titleAr': 'تطوير المهارات',
            'duration': 60,
            'priority': TaskPriority.orange,
          },
          {
            'titleEn': 'Networking',
            'titleAr': 'بناء الشبكة المهنية',
            'duration': 30,
            'priority': TaskPriority.yellow,
          },
        ]);
        break;
      case 'finance':
        tasks.addAll([
          {
            'titleEn': 'Financial Review',
            'titleAr': 'مراجعة مالية',
            'duration': 30,
            'priority': TaskPriority.red,
          },
          {
            'titleEn': 'Budget Planning',
            'titleAr': 'تخطيط الميزانية',
            'duration': 45,
            'priority': TaskPriority.orange,
          },
          {
            'titleEn': 'Investment Research',
            'titleAr': 'بحث الاستثمارات',
            'duration': 60,
            'priority': TaskPriority.orange,
          },
        ]);
        break;
      case 'learning':
        tasks.addAll([
          {
            'titleEn': 'Study Session',
            'titleAr': 'جلسة دراسة',
            'duration': 90,
            'priority': TaskPriority.red,
          },
          {
            'titleEn': 'Practice Exercise',
            'titleAr': 'تمرين تطبيقي',
            'duration': 45,
            'priority': TaskPriority.orange,
          },
          {
            'titleEn': 'Review Notes',
            'titleAr': 'مراجعة الملاحظات',
            'duration': 30,
            'priority': TaskPriority.yellow,
          },
        ]);
        break;
      default:
        tasks.addAll([
          {
            'titleEn': 'Work on ${goal.titleEn}',
            'titleAr': 'العمل على ${goal.titleAr}',
            'duration': 60,
            'priority': TaskPriority.orange,
          },
          {
            'titleEn': 'Review Progress',
            'titleAr': 'مراجعة التقدم',
            'duration': 30,
            'priority': TaskPriority.yellow,
          },
        ]);
    }

    return tasks;
  }

  /// Calculate simple productivity score (0-100)
  static int calculateProductivityScore({
    required List<TimeBlockModel> completedBlocks,
    required List<HabitModel> habits,
    required DateTime date,
  }) {
    int score = 0;

    // Task completion component (60 points)
    final todayBlocks = completedBlocks.where((b) => b.isForDate(date)).toList();
    if (todayBlocks.isNotEmpty) {
      final completedCount = todayBlocks.where((b) => b.isCompleted).length;
      score += ((completedCount / todayBlocks.length) * 60).round();
    }

    // Habit completion component (40 points)
    final activeHabits = habits.where((h) => h.isDaily).toList();
    if (activeHabits.isNotEmpty) {
      final completedHabits =
          activeHabits.where((h) => h.isCompletedToday()).length;
      score += ((completedHabits / activeHabits.length) * 40).round();
    }

    return score.clamp(0, 100);
  }
}

// ==================== Private Helper Classes ====================

class _ScoredTask {
  final TaskModel task;
  final double score;
  bool assigned = false;

  _ScoredTask({required this.task, required this.score});
}

class _TimeRange {
  final int startMinutes;
  final int endMinutes;

  _TimeRange({required this.startMinutes, required this.endMinutes});
}

class _TimeSlot {
  final int startMinutes;
  final int endMinutes;
  final _EnergyZone energyZone;

  _TimeSlot({
    required this.startMinutes,
    required this.endMinutes,
    required this.energyZone,
  });

  int get availableMinutes => endMinutes - startMinutes;
}

enum _EnergyZone { deepWork, learning, medium, light }
