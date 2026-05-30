import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/goal_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/time_block_model.dart';
import '../../data/repositories/scheduling_engine.dart';
import '../../core/theme/app_theme.dart';

// ==================== Settings Providers ====================

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with ProviderScope override');
});

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs)
    : super(_prefs.getString(AppConstants.settingsLanguage) ?? 'en');

  void setLocale(String locale) {
    state = locale;
    _prefs.setString(AppConstants.settingsLanguage, locale);
  }
}

final onboardedProvider = StateNotifierProvider<OnboardedNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardedNotifier(prefs);
});

class OnboardedNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardedNotifier(this._prefs)
    : super(_prefs.getBool(AppConstants.settingsOnboarded) ?? false);

  void setOnboarded() {
    state = true;
    _prefs.setBool(AppConstants.settingsOnboarded, true);
  }
}

// ==================== Goals Providers ====================

final goalsBoxProvider = Provider<Box<GoalModel>>((ref) {
  return Hive.box<GoalModel>(AppConstants.hiveGoalBox);
});

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<GoalModel>>((
  ref,
) {
  final box = ref.watch(goalsBoxProvider);
  return GoalsNotifier(box);
});

class GoalsNotifier extends StateNotifier<List<GoalModel>> {
  final Box<GoalModel> _box;

  GoalsNotifier(this._box) : super(_box.values.toList());

  void _refresh() => state = _box.values.toList();

  Future<void> addGoal(GoalModel goal) async {
    await _box.put(goal.id, goal);
    _refresh();
  }

  Future<void> updateGoal(GoalModel goal) async {
    await _box.put(goal.id, goal);
    _refresh();
  }

  Future<void> deleteGoal(String goalId) async {
    await _box.delete(goalId);
    _refresh();
  }

  Future<void> updateProgress(String goalId, double progress) async {
    final goal = _box.get(goalId);
    if (goal != null) {
      goal.progress = progress.clamp(0.0, 1.0);
      await goal.save();
      _refresh();
    }
  }
}

// ==================== Tasks Providers ====================

final tasksBoxProvider = Provider<Box<TaskModel>>((ref) {
  return Hive.box<TaskModel>(AppConstants.hiveTaskBox);
});

final tasksProvider = StateNotifierProvider<TasksNotifier, List<TaskModel>>((
  ref,
) {
  final box = ref.watch(tasksBoxProvider);
  return TasksNotifier(box);
});

class TasksNotifier extends StateNotifier<List<TaskModel>> {
  final Box<TaskModel> _box;

  TasksNotifier(this._box) : super(_box.values.toList());

  void _refresh() => state = _box.values.toList();

  Future<void> addTask(TaskModel task) async {
    await _box.put(task.id, task);
    _refresh();
  }

  Future<void> updateTask(TaskModel task) async {
    await _box.put(task.id, task);
    _refresh();
  }

  Future<void> deleteTask(String taskId) async {
    await _box.delete(taskId);
    _refresh();
  }

  Future<void> updateStatus(String taskId, TaskStatus status) async {
    final task = _box.get(taskId);
    if (task != null) {
      task.statusIndex = status.index;
      await task.save();
      _refresh();
    }
  }

  List<TaskModel> getTasksForGoal(String goalId) =>
      state.where((t) => t.goalId == goalId).toList();

  List<TaskModel> getPendingTasks() =>
      state
          .where(
            (t) =>
                t.status == TaskStatus.todo ||
                t.status == TaskStatus.inProgress,
          )
          .toList();
}

// ==================== Habits Providers ====================

final habitsBoxProvider = Provider<Box<HabitModel>>((ref) {
  return Hive.box<HabitModel>(AppConstants.hiveHabitBox);
});

final habitsProvider =
    StateNotifierProvider<HabitsNotifier, List<HabitModel>>((ref) {
      final box = ref.watch(habitsBoxProvider);
      return HabitsNotifier(box);
    });

class HabitsNotifier extends StateNotifier<List<HabitModel>> {
  final Box<HabitModel> _box;

  HabitsNotifier(this._box) : super(_box.values.toList());

  void _refresh() => state = _box.values.toList();

  Future<void> addHabit(HabitModel habit) async {
    await _box.put(habit.id, habit);
    _refresh();
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _box.put(habit.id, habit);
    _refresh();
  }

  Future<void> deleteHabit(String habitId) async {
    await _box.delete(habitId);
    _refresh();
  }

  Future<void> toggleCompletion(String habitId) async {
    final habit = _box.get(habitId);
    if (habit != null) {
      habit.markComplete();
      await habit.save();
      _refresh();
    }
  }
}

// ==================== Time Blocks Providers ====================

final timeBlocksBoxProvider = Provider<Box<TimeBlockModel>>((ref) {
  return Hive.box<TimeBlockModel>(AppConstants.hiveTimeBlockBox);
});

final timeBlocksProvider =
    StateNotifierProvider<TimeBlocksNotifier, List<TimeBlockModel>>((ref) {
      final box = ref.watch(timeBlocksBoxProvider);
      return TimeBlocksNotifier(box);
    });

class TimeBlocksNotifier extends StateNotifier<List<TimeBlockModel>> {
  final Box<TimeBlockModel> _box;

  TimeBlocksNotifier(this._box) : super(_box.values.toList());

  void _refresh() => state = _box.values.toList();

  Future<void> generateScheduleForDate(
    DateTime date,
    List<GoalModel> goals,
    List<TaskModel> tasks,
    List<HabitModel> habits,
  ) async {
    // Remove existing blocks for this date
    final keysToDelete = _box.keys
        .where((k) {
          final block = _box.get(k);
          return block != null && block.isForDate(date);
        })
        .toList();
    await _box.deleteAll(keysToDelete);

    // Generate new schedule
    final newBlocks = SchedulingEngine.generateDailySchedule(
      date: date,
      activeGoals: goals.where((g) => g.isActive).toList(),
      pendingTasks: tasks
          .where(
            (t) =>
                t.status == TaskStatus.todo ||
                t.status == TaskStatus.inProgress,
          )
          .toList(),
      habits: habits,
    );

    // Save all new blocks
    for (final block in newBlocks) {
      await _box.put(block.id, block);
    }

    _refresh();
  }

  Future<void> markBlockComplete(String blockId) async {
    final block = _box.get(blockId);
    if (block != null) {
      block.isCompleted = true;
      await block.save();
      _refresh();
    }
  }

  List<TimeBlockModel> getBlocksForDate(DateTime date) =>
      state.where((b) => b.isForDate(date)).toList()
        ..sort((a, b) {
          final aM = a.startHour * 60 + a.startMinute;
          final bM = b.startHour * 60 + b.startMinute;
          return aM.compareTo(bM);
        });

  Future<void> clearAllBlocks() async {
    await _box.clear();
    _refresh();
  }
}

// ==================== Derived / Computed Providers ====================

final todayBlocksProvider = Provider<List<TimeBlockModel>>((ref) {
  final blocks = ref.watch(timeBlocksProvider);
  final today = DateTime.now();
  return blocks
      .where((b) => b.isForDate(today))
      .toList()
    ..sort((a, b) {
      final aM = a.startHour * 60 + a.startMinute;
      final bM = b.startHour * 60 + b.startMinute;
      return aM.compareTo(bM);
    });
});

final goalAlignmentScoreProvider = Provider<int>((ref) {
  final blocks = ref.watch(todayBlocksProvider);
  final tasks = ref.watch(tasksProvider);
  return SchedulingEngine.calculateAlignmentScore(blocks, tasks);
});

final productivityScoreProvider = Provider<int>((ref) {
  final blocks = ref.watch(timeBlocksProvider);
  final habits = ref.watch(habitsProvider);
  return SchedulingEngine.calculateProductivityScore(
    completedBlocks: blocks,
    habits: habits,
    date: DateTime.now(),
  );
});

final top3PrioritiesProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final goals = ref.watch(goalsProvider);

  final pending = tasks
      .where(
        (t) =>
            t.status == TaskStatus.todo || t.status == TaskStatus.inProgress,
      )
      .toList();

  // Sort by priority then goal importance
  final goalMap = {for (var g in goals) g.id: g};
  pending.sort((a, b) {
    final aScore =
        (5 - a.priorityIndex) * 10 + (goalMap[a.goalId]?.priority ?? 0);
    final bScore =
        (5 - b.priorityIndex) * 10 + (goalMap[b.goalId]?.priority ?? 0);
    return bScore.compareTo(aScore);
  });

  return pending.take(3).toList();
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
