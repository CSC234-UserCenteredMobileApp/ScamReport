part of 'settings_screen.dart';

// Security section — biometric / PIN app lock. Gated by the
// `enable_biometric_login` Remote Config flag (see SettingsScreen).
class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appLockControllerProvider);

    return async.when(
      loading: () => const _SettingsSkeleton(height: 72),
      error: (_, __) => const SizedBox.shrink(),
      data: (rt) {
        final config = rt.config;
        return Card(
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Column(
            children: [
              _SecurityToggleTile(
                title: context.l10n.appLockTileTitle,
                subtitle: context.l10n.appLockTileSubtitle,
                value: config.enabled,
                isFirst: true,
                isLast: !config.enabled,
                onChanged: (v) => v
                    ? _enable(context, ref)
                    : _disable(context, ref),
              ),
              if (config.enabled) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SecurityToggleTile(
                  title: context.l10n.appLockUseBiometric,
                  value: config.biometricEnabled,
                  onChanged: (v) => _toggleBiometric(context, ref, v),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _NavTile(
                  icon: Icons.pin_outlined,
                  title: context.l10n.appLockChangePin,
                  onTap: () => _changePin(context, ref),
                  isLast: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final pin = await showPinSetupSheet(context);
    if (pin == null) return;
    await ref.read(appLockControllerProvider.notifier).enableWithPin(pin);
  }

  Future<void> _disable(BuildContext context, WidgetRef ref) async {
    // Re-authenticate before turning protection off.
    final ok = await showPinVerifySheet(
      context,
      heading: context.l10n.appLockDisableHeading,
    );
    if (ok != true) return;
    await ref.read(appLockControllerProvider.notifier).disable();
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final pin = await showPinSetupSheet(context);
    if (pin == null) return;
    await ref.read(appLockControllerProvider.notifier).changePin(pin);
  }

  Future<void> _toggleBiometric(
      BuildContext context, WidgetRef ref, bool enable) async {
    final controller = ref.read(appLockControllerProvider.notifier);
    if (!enable) {
      await controller.setBiometricEnabled(false);
      return;
    }
    final available = await controller.canUseBiometrics();
    if (!available) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appLockBiometricUnavailable)),
        );
      }
      return;
    }
    await controller.setBiometricEnabled(true);
  }
}

class _SecurityToggleTile extends StatelessWidget {
  const _SecurityToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

  final String title;
  final String? subtitle;
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
        secondary: Icon(Icons.lock_outline, color: cs.onSurfaceVariant, size: 22),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
