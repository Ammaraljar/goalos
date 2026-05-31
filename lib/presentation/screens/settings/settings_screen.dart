import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = ref.read(apiKeyProvider);
      _apiKeyCtrl.text = key;
    });
  }

  @override
  void dispose() { _apiKeyCtrl.dispose(); super.dispose(); }

  Future<void> _saveApiKey() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('api_key', _apiKeyCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key saved ✓'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final isAr = locale == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Language
          _Section(title: isAr ? 'اللغة' : 'Language'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _LangBtn(
              flag: '🇺🇸', label: 'English', selected: locale == 'en',
              onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _LangBtn(
              flag: '🇸🇦', label: 'العربية', selected: locale == 'ar',
              onTap: () => ref.read(localeProvider.notifier).setLocale('ar'),
            )),
          ]),
          const SizedBox(height: 28),

          // AI API Key
          _Section(title: isAr ? 'مفتاح الذكاء الاصطناعي' : 'AI API Key'),
          const SizedBox(height: 8),
          Text(
            isAr ? 'أدخل مفتاح Claude API لتفعيل المدرّب الذكي' : 'Enter your Claude API key to enable AI coaching',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: !_showKey,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'sk-ant-...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: Icon(_showKey ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textMuted, size: 20),
                onPressed: () => setState(() => _showKey = !_showKey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveApiKey,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.highlight, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(isAr ? 'حفظ المفتاح' : 'Save API Key', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Get your key at: console.anthropic.com'), backgroundColor: AppColors.info),
            ),
            child: Text(
              isAr ? 'احصل على مفتاحك من console.anthropic.com' : 'Get your key at console.anthropic.com',
              style: const TextStyle(color: AppColors.info, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),

          // Reset Data
          _Section(title: isAr ? 'البيانات' : 'Data'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, ref, l10n, isAr),
            icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
            label: Text(l10n.resetData, style: const TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 40),
          Center(child: Text('GoalOS v1.0.0', style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref, AppLocalizations l10n, bool isAr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(l10n.resetData, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.resetConfirm, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(goalsProvider.notifier).state;
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.setBool(AppConstants.settingsOnboarded, false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isAr ? 'تم حذف البيانات' : 'Data cleared'), backgroundColor: AppColors.error),
                );
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5));
}

class _LangBtn extends StatelessWidget {
  final String flag, label;
  final bool selected;
  final VoidCallback onTap;
  const _LangBtn({required this.flag, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: selected ? AppColors.highlight.withOpacity(0.15) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? AppColors.highlight : Colors.transparent, width: 1.5),
      ),
      child: Column(children: [
        Text(flag, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: selected ? AppColors.highlight : AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
