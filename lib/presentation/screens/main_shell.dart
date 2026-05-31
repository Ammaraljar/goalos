import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/app_providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'goals/goals_screen.dart';
import 'tasks/tasks_screen.dart';
import 'habits/habits_screen.dart';
import 'ai_coach/ai_coach_screen.dart';
import 'settings/settings_screen.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    GoalsScreen(),
    TasksScreen(),
    HabitsScreen(),
    AiCoachScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final isAr = locale == 'ar';

    final items = [
      (Icons.dashboard_rounded, l10n.dashboard),
      (Icons.flag_rounded, l10n.goals),
      (Icons.task_alt_rounded, l10n.tasks),
      (Icons.repeat_rounded, l10n.habits),
      (Icons.psychology_rounded, isAr ? 'مدرّب' : 'Coach'),
      (Icons.settings_rounded, l10n.settings),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.secondary,
          border: Border(top: BorderSide(color: AppColors.surface, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final selected = _selectedIndex == i;
                final isCoach = i == 4;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isCoach ? const Color(0xFF9C27B0).withOpacity(0.2) : AppColors.highlight.withOpacity(0.15))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$1,
                          color: selected
                              ? (isCoach ? const Color(0xFFCE93D8) : AppColors.highlight)
                              : AppColors.textMuted,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(item.$2,
                          style: TextStyle(
                            fontSize: 9,
                            color: selected
                                ? (isCoach ? const Color(0xFFCE93D8) : AppColors.highlight)
                                : AppColors.textMuted,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
