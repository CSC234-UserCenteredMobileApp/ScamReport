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
                  .save(settings.copyWith(
                    regionalAlerts: v,
                    clearProvince: !v,
                  )),
              isLast: !settings.regionalAlerts,
            ),
            if (settings.regionalAlerts) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ProvincePicker(
                value: settings.province,
                onChanged: (p) => ref
                    .read(settingsProvider.notifier)
                    .save(settings.copyWith(province: p)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProvincePicker extends StatelessWidget {
  const _ProvincePicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Province',
            labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: Text(
            'Select province',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          items: kThaiProvinces
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: onChanged,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
