part of 'settings_screen.dart';

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const _SettingsSkeleton(height: 172),
      error: (_, __) => const SizedBox.shrink(),
      data: (settings) => Card(
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          children: [
            _NotifTile(
              title: 'Phone scam alerts',
              subtitle: 'Get notified about new phone scams',
              value: settings.phoneScamAlerts,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .save(settings.copyWith(phoneScamAlerts: v)),
              isFirst: true,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _NotifTile(
              title: 'SMS phishing alerts',
              subtitle: 'Trending SMS scam patterns',
              value: settings.smsPhishingAlerts,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .save(settings.copyWith(smsPhishingAlerts: v)),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _NotifTile(
              title: 'Regional alerts',
              subtitle: 'Scams reported in your province',
              value: settings.regionalAlerts,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .save(settings.copyWith(regionalAlerts: v)),
              isLast: true,
            ),
          ],
        ),
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
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
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
        activeThumbColor: cs.primary,
        activeTrackColor: cs.primary.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
