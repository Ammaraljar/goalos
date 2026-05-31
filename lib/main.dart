import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/models/goal_model.dart';
import 'data/models/task_model.dart';
import 'data/models/habit_model.dart';
import 'data/models/time_block_model.dart';
import 'data/models/sub_goal_model.dart';
import 'data/models/user_behavior_model.dart';
import 'data/models/hive_adapters.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Hive.initFlutter();
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(TimeBlockModelAdapter());
  Hive.registerAdapter(SubGoalModelAdapter());
  Hive.registerAdapter(UserBehaviorModelAdapter());

  await Hive.openBox<GoalModel>(AppConstants.hiveGoalBox);
  await Hive.openBox<TaskModel>(AppConstants.hiveTaskBox);
  await Hive.openBox<HabitModel>(AppConstants.hiveHabitBox);
  await Hive.openBox<TimeBlockModel>(AppConstants.hiveTimeBlockBox);
  await Hive.openBox<SubGoalModel>(AppConstants.hiveSubGoalBox);
  await Hive.openBox<UserBehaviorModel>(AppConstants.hiveBehaviorBox);

  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const GoalOSApp(),
  ));
}

class GoalOSApp extends ConsumerWidget {
  const GoalOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isOnboarded = ref.watch(onboardedProvider);

    return MaterialApp(
      title: 'GoalOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: Locale(locale),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final isRtl = locale == 'ar';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: isOnboarded ? const MainShell() : const OnboardingScreen(),
    );
  }
}
