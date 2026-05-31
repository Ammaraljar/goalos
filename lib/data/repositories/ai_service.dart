import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/goal_model.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/user_behavior_model.dart';

class AIService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';

  final String apiKey;

  AIService({required this.apiKey});

  // ==================== Core API Call ====================
  Future<String> _call(String systemPrompt, String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1500,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        return 'خطأ في الاتصال. كود: ${response.statusCode}';
      }
    } catch (e) {
      return 'خطأ في الاتصال: $e';
    }
  }

  // ==================== Chat with AI Coach ====================
  Future<String> chat({
    required String userMessage,
    required List<GoalModel> goals,
    required List<TaskModel> tasks,
    required List<HabitModel> habits,
    required List<UserBehaviorModel> behaviors,
    required List<Map<String, String>> chatHistory,
    required String locale,
  }) async {
    final isAr = locale == 'ar';

    final goalsStr = goals.map((g) =>
      '- ${g.getTitle(locale)} (${g.category}, ${(g.progress * 100).round()}%, ${g.daysRemaining} days left)'
    ).join('\n');

    final tasksStr = tasks.where((t) => t.status != TaskStatus.done).take(10).map((t) =>
      '- ${t.getTitle(locale)} (${t.priority.name}, ${t.durationMinutes}min)'
    ).join('\n');

    // Analyze behavior patterns
    final completedHours = behaviors
        .where((b) => b.eventType == 'task_completed')
        .map((b) => b.hour)
        .toList();
    String behaviorInsight = '';
    if (completedHours.isNotEmpty) {
      final avgHour = completedHours.reduce((a, b) => a + b) ~/ completedHours.length;
      behaviorInsight = isAr
          ? 'المستخدم أكثر إنتاجية في الساعة $avgHour تقريباً.'
          : 'User is most productive around hour $avgHour.';
    }

    final systemPrompt = isAr ? '''
أنت مدرب حياة ذكي ومحلل سلوكي متخصص في تحقيق الأهداف. اسمك GoalOS Coach.

قواعدك:
- تحدث بالعربية دائماً
- كن مباشراً وعملياً — لا كلام فارغ
- كل نصيحة يجب أن تكون قابلة للتنفيذ الآن
- راعي سلوك المستخدم الفعلي عند التوجيه
- اقترح أوقاتاً محددة للمهام بناءً على نمط المستخدم

أهداف المستخدم:
$goalsStr

المهام المعلقة:
$tasksStr

تحليل سلوك المستخدم:
$behaviorInsight

أجب بإيجاز وبشكل منظم. استخدم الترقيم والنقاط عند الحاجة.
''' : '''
You are GoalOS Coach — an intelligent life coach and behavioral analyst specialized in goal achievement.

Rules:
- Be direct and practical — no fluff
- Every piece of advice must be immediately actionable
- Factor in user's actual behavior patterns when giving guidance
- Suggest specific times based on user patterns

User Goals:
$goalsStr

Pending Tasks:
$tasksStr

Behavior Insight:
$behaviorInsight

Be concise and structured. Use numbered lists when helpful.
''';

    // Build conversation history
    final messages = <Map<String, String>>[];
    for (final msg in chatHistory.take(10)) {
      messages.add(msg);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1000,
          'system': systemPrompt,
          'messages': [
            ...messages,
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
      return isAr ? 'حدث خطأ. حاول مجدداً.' : 'An error occurred. Please try again.';
    } catch (e) {
      return isAr ? 'خطأ في الاتصال: $e' : 'Connection error: $e';
    }
  }

  // ==================== AI Goal Decomposition ====================
  Future<Map<String, dynamic>> decomposeGoal({
    required GoalModel goal,
    required String locale,
  }) async {
    final isAr = locale == 'ar';
    final prompt = isAr ? '''
قم بتحليل هذا الهدف وأنشئ خطة تنفيذ كاملة:

الهدف: ${goal.titleAr.isNotEmpty ? goal.titleAr : goal.titleEn}
الفئة: ${goal.category}
الأولوية: ${goal.priority}/10
الأيام المتبقية: ${goal.daysRemaining}
التقدم الحالي: ${(goal.progress * 100).round()}%

أنشئ JSON بالتنسيق التالي فقط، بدون أي نص إضافي:
{
  "subGoals": [
    {"titleAr": "...", "titleEn": "...", "weeks": 4}
  ],
  "tasks": [
    {"titleAr": "...", "titleEn": "...", "durationMinutes": 60, "priority": "red|orange|yellow|green"}
  ],
  "habits": [
    {"titleAr": "...", "titleEn": "...", "frequencyDays": 1}
  ],
  "insight": "نصيحة مختصرة للنجاح"
}
''' : '''
Analyze this goal and create a complete execution plan:

Goal: ${goal.titleEn}
Category: ${goal.category}
Priority: ${goal.priority}/10
Days remaining: ${goal.daysRemaining}
Current progress: ${(goal.progress * 100).round()}%

Return ONLY this JSON format, no extra text:
{
  "subGoals": [
    {"titleAr": "...", "titleEn": "...", "weeks": 4}
  ],
  "tasks": [
    {"titleAr": "...", "titleEn": "...", "durationMinutes": 60, "priority": "red|orange|yellow|green"}
  ],
  "habits": [
    {"titleAr": "...", "titleEn": "...", "frequencyDays": 1}
  ],
  "insight": "Brief success tip"
}
''';

    final response = await _call('You are a goal decomposition expert. Return only valid JSON.', prompt);

    try {
      final jsonStr = response.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {
        'subGoals': [],
        'tasks': [],
        'habits': [],
        'insight': isAr ? 'ابدأ بخطوة صغيرة اليوم' : 'Start with a small step today',
      };
    }
  }

  // ==================== AI Daily Plan ====================
  Future<String> generateDailyPlan({
    required List<GoalModel> goals,
    required List<TaskModel> pendingTasks,
    required List<HabitModel> habits,
    required List<UserBehaviorModel> behaviors,
    required String locale,
  }) async {
    final isAr = locale == 'ar';

    // Find user's peak hours from behavior
    final completedByHour = <int, int>{};
    for (final b in behaviors.where((b) => b.eventType == 'task_completed')) {
      completedByHour[b.hour] = (completedByHour[b.hour] ?? 0) + 1;
    }
    String peakHours = isAr ? 'الصباح' : 'morning';
    if (completedByHour.isNotEmpty) {
      final peak = completedByHour.entries.reduce((a, b) => a.value > b.value ? a : b);
      peakHours = '${peak.key}:00';
    }

    final topGoals = goals.take(3).map((g) => g.getTitle(locale)).join(', ');
    final topTasks = pendingTasks.take(5).map((t) => '${t.getTitle(locale)} (${t.durationMinutes}min)').join('\n');

    final prompt = isAr ? '''
أنشئ خطة يوم مثالية بناءً على:
- الأهداف الرئيسية: $topGoals
- أوقات ذروة الإنتاجية: $peakHours
- المهام المعلقة:
$topTasks

أنشئ جدولاً ساعياً من 6 صباحاً حتى 10 مساءً مع مراعاة أوقات الراحة والصلاة.
كن محدداً وعملياً. استخدم رموز الأولوية: 🔴 استراتيجي، 🟠 مهم، 🟡 عادي، 🟢 صحة.
''' : '''
Create an optimal day plan based on:
- Top goals: $topGoals
- Peak productivity hours: $peakHours
- Pending tasks:
$topTasks

Create an hourly schedule from 6AM to 10PM with breaks.
Be specific and practical. Use priority symbols: 🔴 strategic, 🟠 important, 🟡 normal, 🟢 health.
''';

    return await _call(
      isAr ? 'أنت مخطط يومي خبير. أنشئ جداول واقعية وقابلة للتنفيذ.' : 'You are an expert daily planner. Create realistic actionable schedules.',
      prompt,
    );
  }

  // ==================== Weekly Review ====================
  Future<String> weeklyReview({
    required List<GoalModel> goals,
    required List<TaskModel> completedTasks,
    required List<TaskModel> missedTasks,
    required List<HabitModel> habits,
    required String locale,
  }) async {
    final isAr = locale == 'ar';
    final completionRate = completedTasks.length /
        (completedTasks.length + missedTasks.length).clamp(1, 9999) * 100;

    final prompt = isAr ? '''
قدّم تقرير أسبوعي شامل:
- معدل إنجاز المهام: ${completionRate.round()}%
- المهام المنجزة: ${completedTasks.length}
- المهام الفائتة: ${missedTasks.length}
- الأهداف النشطة: ${goals.length}

حلّل الأداء وقدّم:
1. ما تم إنجازه بشكل جيد
2. نقاط التحسين
3. خطة الأسبوع القادم
4. نصيحة واحدة محورية
''' : '''
Provide a comprehensive weekly review:
- Task completion rate: ${completionRate.round()}%
- Completed tasks: ${completedTasks.length}
- Missed tasks: ${missedTasks.length}
- Active goals: ${goals.length}

Analyze performance and provide:
1. What went well
2. Areas for improvement
3. Next week's plan
4. One key piece of advice
''';

    return await _call(
      isAr ? 'أنت محلل أداء خبير. قدّم تقارير دقيقة وموجهة نحو التحسين.' : 'You are an expert performance analyst. Provide accurate improvement-focused reports.',
      prompt,
    );
  }
}
