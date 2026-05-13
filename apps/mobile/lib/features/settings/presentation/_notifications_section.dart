part of 'settings_screen.dart';

// Alerts & Protection section — push notification toggles + active device
// protection (call screening, SMS scanning). Android-only items are hidden
// on web and other platforms.
class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return settingsAsync.when(
      loading: () => const _SettingsSkeleton(height: 160),
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
              isLast: !isAndroid,
            ),
            if (isAndroid) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              const _CallScreeningTile(),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SmsToggleTile(settings: settings),
            ],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _CallScreeningTile extends StatelessWidget {
  const _CallScreeningTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: ListTile(
        leading: Icon(Icons.phone_in_talk_outlined,
            color: cs.onSurfaceVariant, size: 22),
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

class _SmsToggleTile extends ConsumerWidget {
  const _SmsToggleTile({required this.settings});

  final SettingsState settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          context.l10n.smsSmishingDetectionDesc,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        value: settings.smsScanning,
        onChanged: (v) => _onToggle(context, ref, v),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Future<void> _onToggle(
      BuildContext context, WidgetRef ref, bool enable) async {
    if (!enable) {
      await ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(smsScanning: false));
      return;
    }

    final settingsRepo = ref.read(settingsRepositoryProvider);
    final consentGiven = settingsRepo.smsScanConsentGiven;
    if (!consentGiven) {
      if (!context.mounted) return;
      final agreed = await _showSmsConsentDialog(context);
      if (!agreed || !context.mounted) return;
      await settingsRepo.setSmsScanConsentGiven();
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

    await ref
        .read(settingsProvider.notifier)
        .save(settings.copyWith(smsScanning: true));
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
