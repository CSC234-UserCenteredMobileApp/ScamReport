part of 'settings_screen.dart';

class _PreferencesSection extends ConsumerWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const _SettingsSkeleton(height: 116),
      error: (_, __) => const SizedBox.shrink(),
      data: (settings) => Card(
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          children: [
            _PrefRow(
              icon: Icons.language_outlined,
              label: context.l10n.languageLabel,
              isFirst: true,
              trailing: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'en', label: Text(context.l10n.languageEnglish)),
                  ButtonSegment(value: 'th', label: Text(context.l10n.languageThai)),
                ],
                selected: {settings.language},
                onSelectionChanged: (s) => ref
                    .read(settingsProvider.notifier)
                    .save(settings.copyWith(language: s.first)),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.primary,
                  selectedForegroundColor:
                      Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _PrefRow(
              icon: Icons.visibility_outlined,
              label: context.l10n.themeLabel,
              isLast: true,
              trailing: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(value: ThemeMode.light, label: Text(context.l10n.themeLight)),
                  ButtonSegment(value: ThemeMode.dark, label: Text(context.l10n.themeDark)),
                ],
                selected: {
                  settings.themeMode == ThemeMode.system
                      ? ThemeMode.light
                      : settings.themeMode,
                },
                onSelectionChanged: (s) => ref
                    .read(settingsProvider.notifier)
                    .save(settings.copyWith(themeMode: s.first)),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.primary,
                  selectedForegroundColor:
                      Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefRow extends StatelessWidget {
  const _PrefRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: radius,
      child: ListTile(
        leading: Icon(icon, color: cs.onSurfaceVariant, size: 22),
        title: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
