import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_settings_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    AppSettingsStore.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: AnimatedBuilder(
        animation: AppSettingsStore.instance,
        builder: (context, _) {
          final settings = AppSettingsStore.instance;
          if (!settings.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSection(
                title: 'Для слепошариков',
                subtitle: 'Быстрое усиление читаемости интерфейса.',
                children: [
                  SwitchListTile.adaptive(
                    value: settings.largeTextEnabled,
                    onChanged: settings.setLargeTextEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Увеличенный текст'),
                    subtitle: const Text(
                      'Делает текст в приложении крупнее и чуть легче для чтения в поле.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: 'Просмотр схем',
                subtitle: 'Настройки для PDF и работы со схемами.',
                children: [
                  SwitchListTile.adaptive(
                    value: settings.keepScreenAwakeInPdf,
                    onChanged: settings.setKeepScreenAwakeInPdf,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Не выключать экран в схеме'),
                    subtitle: const Text(
                      'Пока открыт PDF, экран будет оставаться активным.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsSection(
                title: 'Тема',
                subtitle: 'Переключение внешнего вида приложения.',
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ThemeChoiceChip(
                        label: 'Тёмная',
                        icon: Icons.dark_mode_outlined,
                        isSelected:
                            settings.themePreference == AppThemePreference.dark,
                        onTap: () => settings.setThemePreference(
                          AppThemePreference.dark,
                        ),
                      ),
                      _ThemeChoiceChip(
                        label: 'Светлая',
                        icon: Icons.light_mode_outlined,
                        isSelected: settings.themePreference ==
                            AppThemePreference.light,
                        onTap: () => settings.setThemePreference(
                          AppThemePreference.light,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SettingsSection(
                title: 'О поведении',
                subtitle: 'Как приложение ведёт себя при работе со схемами.',
                children: [
                  _SettingsHint(
                    text:
                        'Схема будет открываться с последней страницы и приблизительно тем же масштабом, где ты её закрыл.',
                  ),
                  _SettingsHint(
                    text:
                        'PDF грузятся через память-кэш, чтобы повторные открытия были заметно спокойнее.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SettingsSection(
                title: 'О программе',
                subtitle: 'Немного о смысле и отношении к этой технике.',
                children: [
                  _SettingsHint(
                    text:
                        'С уважением и пониманием к сервису.\nСоздатель MobileTechnology (РябкоFF).',
                  ),
                  _SettingsHint(
                    text:
                        'Бережно относитесь к этой технике: она как капризная девушка. С ней не надо грубостей, ей просто нужна душа, которой ей не хватает.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SettingsSection(
                title: 'Поддержка',
                subtitle: 'Для донатов и поддержки проекта.',
                children: [
                  _CopyableSupportCard(
                    label: 'T-Банк',
                    phone: '+7 965 946-25-26',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CopyableSupportCard extends StatelessWidget {
  final String label;
  final String phone;

  const _CopyableSupportCard({
    required this.label,
    required this.phone,
  });

  String get _digitsOnly => phone.replaceAll(RegExp(r'\D'), '');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: _digitsOnly));
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Номер скопирован')),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x14FF8A3D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x44FF8A3D)),
        ),
        child: Row(
          children: [
            const Icon(Icons.content_copy_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$label · $phone',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChoiceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.16)
              : Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHint extends StatelessWidget {
  final String text;

  const _SettingsHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
