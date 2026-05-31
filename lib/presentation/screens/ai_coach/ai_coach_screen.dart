import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/ai_service.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;
  String _activeTab = 'chat'; // chat | plan | review

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendWelcome());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  AIService get _ai {
    final key = ref.read(apiKeyProvider);
    return AIService(apiKey: key);
  }

  void _sendWelcome() {
    final locale = ref.read(localeProvider);
    final isAr = locale == 'ar';
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': isAr
            ? '👋 أهلاً! أنا مدرّبك الذكي في GoalOS.\n\nأستطيع مساعدتك في:\n🎯 تحليل أهدافك\n📅 إنشاء خطة يومية مثالية\n📊 مراجعة أدائك الأسبوعي\n💡 توجيهك لإنجاز المهام\n\nكيف يمكنني مساعدتك اليوم؟'
            : '👋 Hello! I\'m your GoalOS AI Coach.\n\nI can help you with:\n🎯 Analyzing your goals\n📅 Creating an optimal daily plan\n📊 Weekly performance review\n💡 Guiding you to complete tasks\n\nHow can I help you today?',
      });
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    final locale = ref.read(localeProvider);
    final goals = ref.read(goalsProvider);
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider);
    final behaviors = ref.read(behaviorsProvider);

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _ctrl.clear();
    _scrollDown();

    final response = await _ai.chat(
      userMessage: text,
      goals: goals,
      tasks: tasks,
      habits: habits,
      behaviors: behaviors,
      chatHistory: _messages.where((m) => m['role'] != 'assistant' || _messages.indexOf(m) > 0).toList(),
      locale: locale,
    );

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _loading = false;
      });
      _scrollDown();
    }
  }

  Future<void> _generateDailyPlan() async {
    final locale = ref.read(localeProvider);
    final isAr = locale == 'ar';
    final goals = ref.read(goalsProvider);
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider);
    final behaviors = ref.read(behaviorsProvider);

    setState(() {
      _activeTab = 'plan';
      _messages.add({'role': 'user', 'content': isAr ? '📅 أنشئ لي خطة يوم مثالية' : '📅 Generate my optimal daily plan'});
      _loading = true;
    });
    _scrollDown();

    final response = await _ai.generateDailyPlan(
      goals: goals,
      pendingTasks: tasks,
      habits: habits,
      behaviors: behaviors,
      locale: locale,
    );

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _loading = false;
      });
      _scrollDown();
    }
  }

  Future<void> _weeklyReview() async {
    final locale = ref.read(localeProvider);
    final isAr = locale == 'ar';
    final goals = ref.read(goalsProvider);
    final tasks = ref.read(tasksProvider);
    final habits = ref.read(habitsProvider);

    final completed = tasks.where((t) => t.status.index == 2).toList();
    final missed = tasks.where((t) => t.status.index == 0).toList();

    setState(() {
      _activeTab = 'review';
      _messages.add({'role': 'user', 'content': isAr ? '📊 قدّم لي تقرير الأسبوع' : '📊 Give me my weekly review'});
      _loading = true;
    });
    _scrollDown();

    final response = await _ai.weeklyReview(
      goals: goals,
      completedTasks: completed,
      missedTasks: missed,
      habits: habits,
      locale: locale,
    );

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _loading = false;
      });
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isAr = locale == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.highlight, Color(0xFF9C27B0)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isAr ? 'مدرّب GoalOS' : 'GoalOS Coach',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(isAr ? 'مدعوم بالذكاء الاصطناعي' : 'Powered by AI',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          // Quick Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.secondary,
            child: Row(children: [
              _QuickBtn(
                icon: Icons.calendar_today_rounded,
                label: isAr ? 'خطة اليوم' : 'Daily Plan',
                onTap: _generateDailyPlan,
              ),
              const SizedBox(width: 8),
              _QuickBtn(
                icon: Icons.bar_chart_rounded,
                label: isAr ? 'تقرير أسبوعي' : 'Weekly Review',
                onTap: _weeklyReview,
              ),
              const SizedBox(width: 8),
              _QuickBtn(
                icon: Icons.lightbulb_rounded,
                label: isAr ? 'نصيحة' : 'Tip',
                onTap: () {
                  _ctrl.text = isAr ? 'أعطني نصيحة لتحقيق أهدافي اليوم' : 'Give me a tip to achieve my goals today';
                  _send();
                },
              ),
            ]),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return const _TypingIndicator();
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return _MessageBubble(
                  text: msg['content'] ?? '',
                  isUser: isUser,
                );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              border: Border(top: BorderSide(color: AppColors.surface)),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: null,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: isAr ? 'اسأل مدرّبك...' : 'Ask your coach...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _loading ? AppColors.textMuted : AppColors.highlight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _loading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    color: Colors.white, size: 20,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.highlight : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontSize: 14, height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _Dot(delay: 0),
          const SizedBox(width: 4),
          _Dot(delay: 200),
          const SizedBox(width: 4),
          _Dot(delay: 400),
        ]),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
  );
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.highlight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.highlight.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppColors.highlight, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.highlight, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
