part of 'home_screen.dart';

class _BrandHeader extends ConsumerWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;

    final String greeting;
    final Widget avatar;

    if (user == null) {
      greeting = context.l10n.greetingGuest;
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outline,
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      );
    } else {
      final String rawName = user.displayName?.isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? '');
      final String displayFirst = rawName.split(' ').first;
      greeting = context.l10n.greetingWithName(displayFirst);
      final String initials = rawName.isNotEmpty ? rawName[0].toUpperCase() : '?';
      avatar = CircleAvatar(
        radius: 20,
        backgroundColor: theme.colorScheme.primary,
        child: Text(
          initials,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              context.l10n.tagline,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
