part of 'settings_screen.dart';

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final showCallScreening =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
            _NotifTile(
              title: context.l10n.notifPhoneScam,
              subtitle: context.l10n.notifPhoneScamDesc,
              value: settings.phoneScamAlerts,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .save(settings.copyWith(phoneScamAlerts: v)),
              isFirst: true,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _NotifTile(
              title: context.l10n.notifSmsPhishing,
              subtitle: context.l10n.notifSmsPhishingDesc,
              value: settings.smsPhishingAlerts,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .save(settings.copyWith(smsPhishingAlerts: v)),
            ),
            if (showCallScreening) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              const _CallScreeningTile(),
            ],
          ],
        ),
      ),
    );
  }
}

class _CallScreeningTile extends StatelessWidget {
  const _CallScreeningTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const radius = BorderRadius.vertical(bottom: Radius.circular(16));
    return ClipRRect(
      borderRadius: radius,
      child: ListTile(
        leading: Icon(Icons.phone_in_talk_outlined, color: cs.onSurfaceVariant, size: 22),
        title: Text(
          context.l10n.callScreeningTitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          context.l10n.callScreeningSettingsSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: () => context.push('/me/call-screening'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isFirst = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: radius,
      child: SwitchListTile(
        title: Text(title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant)),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
