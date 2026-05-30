import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: l10n.language,
            children: [
              _LanguageTile(
                label: l10n.english,
                subtitle: 'English (LTR)',
                localeCode: 'en',
                isSelected: locale == 'en',
                onTap: () =>
                    ref.read(localeProvider.notifier).setLocale('en'),
              ),
              _LanguageTile(
                label: l10n.arabic,
                subtitle: 'العربية (RTL)',
                localeCode: 'ar',
                isSelected: locale == 'ar',
                onTap: () =>
                    ref.read(localeProvider.notifier).setLocale('ar'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsSection(
            title: 'Data',
            children: [
              ListTile(
                tileColor: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                ),
                title: Text(
                  l10n.resetData,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () => _confirmReset(context, ref, l10n),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  'GoalOS',
                  style: TextStyle(
                    color: AppColors.highlight,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'v1.0.0 — Offline AI Life Execution System',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          l10n.resetData,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.resetConfirm,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Clear all data
              await ref.read(goalsBoxProvider).clear();
              await ref.read(tasksBoxProvider).clear();
              await ref.read(habitsBoxProvider).clear();
              await ref.read(timeBlocksBoxProvider).clear();
              ref.invalidate(goalsProvider);
              ref.invalidate(tasksProvider);
              ref.invalidate(habitsProvider);
              ref.invalidate(timeBlocksProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String localeCode;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.subtitle,
    required this.localeCode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Text(
        localeCode == 'en' ? '🇬🇧' : '🇸🇦',
        style: const TextStyle(fontSize: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.highlight : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.highlight)
          : null,
      onTap: onTap,
    );
  }
}
