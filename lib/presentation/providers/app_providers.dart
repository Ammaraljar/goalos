import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/goal_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/time_block_model.dart';
import '../../data/models/sub_goal_model.dart';
import '../../data/models/user_behavior_model.dart';
import '../../data/repositories/scheduling_engine.dart';
import '../../core/theme/app_theme.dart';

// ==================== Settings ====================
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  LocaleNotifier(this._prefs) : super(_prefs.getString(AppConstants.settingsLanguage) ?? 'en');
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
  OnboardedNotifier(this._prefs) : super(_prefs.getBool(AppConstants.settingsOnboarded) ?? false);
  void setOnboarded() {
    state = true;
    _prefs.setBool(AppConstants.settingsOnboarded, true);
  }
}

final apiKeyProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('api_key') ?? '';
});

// ==================== Goals ====================
final goalsBoxProvider = Provider<Box<GoalModel>>((ref) => Hive.box<GoalModel>(AppConstants.hiveGoalBox));

final goalsProvider = StateNotifierProvider<GoalsNotifier, List<GoalModel>>((ref) {
  return GoalsNotifier(ref.watch(goalsBoxProvider));
});

class GoalsNotifier extends StateNotifier<List<GoalModel>> {
  final Box<GoalModel> _box;
  GoalsNotifier(this._box) : super(_box.values.toList());
  void _refresh() => state = _box.values.toList();
  Future<void> addGoal(GoalModel goal) async { await _box.put(goal.id, goal); _refresh(); }
  Future<void> updateGoal(GoalModel goal) async { await _box.put(goal.id, goal); _refresh(); }
  Future<void> deleteGoal(String id) async { await _box.delete(id); _refresh(); }
  Future<void> updateProgress(String id, double progress) async {
    final goal = _box.get(id);
    if (goal != null) { goal.progress = progress.clamp(0.0, 1.0); await goal.save(); _refresh(); }
  }
}

// ==================== Sub Goals ====================
final subGoalsBoxProvider = Provider<Box<SubGoalModel>>((ref) => Hive.box<SubGoalModel>(AppConstants.hiveSubGoalBox));

final subGoalsProvider = StateNotifierProvider<SubGoalsNotifier, List<SubGoalModel>>((ref) {
  return SubGoalsNotifier(ref.watch(subGoalsBoxProvider));
});

class SubGoalsNotifier extends StateNotifier<List<SubGoalModel>> {
  final Box<SubGoalModel> _box;
  SubGoalsNotifier(this._box) : super(_box.values.toList());
  void _refresh() => state = _box.values.toList();
  Future<void> addSubGoal(SubGoalModel sg) async { await _box.put(sg.id, sg); _refresh(); }
  Future<void> updateSubGoal(SubGoalModel sg) async { await _box.put(sg.id, sg); _refresh(); }
  Future<void> deleteSubGoal(String id) async { await _box.delete(id); _refresh(); }
  Future<void> toggleComplete(String id) async {
    final sg = _box.get(id);
    if (sg != null) { sg.isCompleted = !sg.isCompleted; sg.progress = sg.isCompleted ? 1.0 : 0.0; await sg.save(); _refresh(); }
  }
  List<SubGoalModel> forGoal(String goalId) => state.where((sg) => sg.parentGoalId == goalId).toList();
}

// ==================== Tasks ====================
final tasksBoxProvider = Provider<Box<TaskModel>>((ref) => Hive.box<TaskModel>(AppConstants.hiveTaskBox));

final tasksProvider = StateNotifierProvider<TasksNotifier, List<TaskModel>>((ref) {
  return TasksNotifier(ref.watch(tasksBoxProvider));
});

class TasksNotifier extends StateNotifier<List<TaskModel>> {
  final Box<TaskModel> _box;
  TasksNotifier(this._box) : super(_box.values.toList());
  void _refresh() => state = _box.values.toList();
  Future<void> addTask(TaskModel task) async { await _box.put(task.id, task); _refresh(); }
  Future<void> updateTask(TaskModel task) async { await _box.put(task.id, task); _refresh(); }
  Future<void> deleteTask(String id) async { await _box.delete(id); _refresh(); }
  Future<void> updateStatus(String id, TaskStatus status) async {
    final task = _box.get(id);
    if (task != null) { task.statusIndex = status.index; await task.save(); _refresh(); }
  }
  List<TaskModel> getForGoal(String goalId) => state.where((t) => t.goalId == goalId).toList();
  List<TaskModel> getPending() => state.where((t) => t.status != TaskStatus.done).toList();
}

// ==================== Habits ====================
final habitsBoxProvider = Provider<Box<HabitModel>>((ref) => Hive.box<HabitModel>(AppConstants.hiveHabitBox));

final habitsProvider = StateNotifierProvider<HabitsNotifier, List<HabitModel>>((ref) {
  return HabitsNotifier(ref.watch(habitsBoxProvider));
});

class HabitsNotifier extends StateNotifier<List<HabitModel>> {
  final Box<HabitModel> _box;
  HabitsNotifier(this._box) : super(_box.values.toList());
  void _refresh() => state = _box.values.toList();
  Future<void> addHabit(HabitModel h) async { await _box.put(h.id, h); _refresh(); }
  Future<void> updateHabit(HabitModel h) async { await _box.put(h.id, h); _refresh(); }
  Future<void> deleteHabit(String id) async { await _box.delete(id); _refresh(); }
  Future<void> toggleCompletion(String id) async {
    final h = _box.get(id);
    if (h != null) { h.markComplete(); await h.save(); _refresh(); }
  }
}

// ==================== Time Blocks ====================
final timeBlocksBoxProvider = Provider<Box<TimeBlockModel>>((ref) => Hive.box<TimeBlockModel>(AppConstants.hiveTimeBlockBox));

final timeBlocksProvider = StateNotifierProvider<TimeBlocksNotifier, List<TimeBlockModel>>((ref) {
  return TimeBlocksNotifier(ref.watch(timeBlocksBoxProvider));
});

class TimeBlocksNotifier extends StateNotifier<List<TimeBlockModel>> {
  final Box<TimeBlockModel> _box;
  TimeBlocksNotifier(this._box) : super(_box.values.toList());
  void _refresh() => state = _box.values.toList();
  Future<void> generateForDate(DateTime date, List<GoalModel> goals, List<TaskModel> tasks, List<HabitModel> habits) async {
    final toDelete = _box.keys.where((k) { final b = _box.get(k); return b != null && b.isForDate(date); }).toList();
    await _box.deleteAll(toDelete);
    final blocks = SchedulingEngine.generateDailySchedule(date: date, activeGoals: goals.where((g) => g.isActive).toList(), pendingTasks: tasks.where((t) => t.status != TaskStatus.done).toList(), habits: habits);
    for (final b in blocks) { await _box.put(b.id, b); }
    _refresh();
  }
  Future<void> markComplete(String id) async {
    final b = _box.get(id);
    if (b != null) { b.isCompleted = true; await b.save(); _refresh(); }
  }
  List<TimeBlockModel> forDate(DateTime date) => state.where((b) => b.isForDate(date)).toList()
    ..sort((a, b) => (a.startHour * 60 + a.startMinute).compareTo(b.startHour * 60 + b.startMinute));
}

// ==================== User Behavior ====================
final behaviorsBoxProvider = Provider<Box<UserBehaviorModel>>((ref) => Hive.box<UserBehaviorModel>(AppConstants.hiveBehaviorBox));

final behaviorsProvider = StateNotifierProvider<BehaviorsNotifier, List<UserBehaviorModel>>((ref) {
  return BehaviorsNotifier(ref.watch(behaviorsBoxProvider));
});

class BehaviorsNotifier extends StateNotifier<List<UserBehaviorModel>> {
  final Box<UserBehaviorModel> _box;
  BehaviorsNotifier(this._box) : super(_box.values.toList());
  void _refresh() => state = _box.values.toList();
  Future<void> logEvent({required String eventType, String? relatedId, required String category}) async {
    final now = DateTime.now();
    final b = UserBehaviorModel(eventType: eventType, relatedId: relatedId, hour: now.hour, dayOfWeek: now.weekday, category: category, timestamp: now);
    await _box.put(b.id, b);
    _refresh();
  }
}

// ==================== Computed ====================
final todayBlocksProvider = Provider<List<TimeBlockModel>>((ref) {
  final blocks = ref.watch(timeBlocksProvider);
  final today = DateTime.now();
  return blocks.where((b) => b.isForDate(today)).toList()
    ..sort((a, b) => (a.startHour * 60 + a.startMinute).compareTo(b.startHour * 60 + b.startMinute));
});

final goalAlignmentScoreProvider = Provider<int>((ref) {
  final blocks = ref.watch(todayBlocksProvider);
  final tasks = ref.watch(tasksProvider);
  return SchedulingEngine.calculateAlignmentScore(blocks, tasks);
});

final productivityScoreProvider = Provider<int>((ref) {
  final blocks = ref.watch(timeBlocksProvider);
  final habits = ref.watch(habitsProvider);
  return SchedulingEngine.calculateProductivityScore(completedBlocks: blocks, habits: habits, date: DateTime.now());
});

final top3PrioritiesProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final goals = ref.watch(goalsProvider);
  final goalMap = {for (var g in goals) g.id: g};
  final pending = tasks.where((t) => t.status != TaskStatus.done).toList();
  pending.sort((a, b) {
    final aScore = (5 - a.priorityIndex) * 10 + (goalMap[a.goalId]?.priority ?? 0);
    final bScore = (5 - b.priorityIndex) * 10 + (goalMap[b.goalId]?.priority ?? 0);
    return bScore.compareTo(aScore);
  });
  return pending.take(3).toList();
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
