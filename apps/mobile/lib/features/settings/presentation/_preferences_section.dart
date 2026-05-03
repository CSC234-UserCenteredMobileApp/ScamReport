part of 'settings_screen.dart';

class _PreferencesSection extends ConsumerWidget {
  const _PreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const _SettingsSkeleton(height: 116),
      error: (_, __) => const SizedBox.shrink(),
      data: (settings) {
        final showSms = !kIsWeb && Platform.isAndroid;
        return Card(
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
                isLast: !showSms,
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
              if (showSms) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SmsToggleTile(settings: settings, ref: ref),
              ],
            ],
          ),
        );
      },
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

class _SmsToggleTile extends StatelessWidget {
  const _SmsToggleTile({required this.settings, required this.ref});

  final SettingsState settings;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: SwitchListTile(
        secondary: Icon(
          Icons.sms_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 22,
        ),
        title: Text(
          context.l10n.smsSmishingDetectionLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          context.l10n.smsSmishingDetectionDesc,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        value: settings.smsScanning,
        onChanged: (v) => _onToggle(context, v),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Future<void> _onToggle(BuildContext context, bool enable) async {
    if (!enable) {
      await ref.read(settingsProvider.notifier).save(settings.copyWith(smsScanning: false));
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider).requireValue;
    final consentGiven = prefs.getBool('sms_scan_consent_given') ?? false;
    if (!consentGiven) {
      if (!context.mounted) return;
      final agreed = await _showSmsConsentDialog(context);
      if (!agreed || !context.mounted) return;
      await prefs.setBool('sms_scan_consent_given', true);
    }

    final status = await Permission.sms.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.smsPermissionDenied)),
        );
      }
      return;
    }

    await ref.read(settingsProvider.notifier).save(settings.copyWith(smsScanning: true));
  }

  Future<bool> _showSmsConsentDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.l10n.smsConsentTitle),
            content: Text(ctx.l10n.smsConsentBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(ctx.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.l10n.smsConsentAgree),
              ),
            ],
          ),
        ) ??
        false;
  }
}
