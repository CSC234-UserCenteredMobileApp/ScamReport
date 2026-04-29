part of 'settings_screen.dart';

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null ? _GuestRow(cs: cs) : _AuthedRow(user: user!, cs: cs),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guest variant
// ---------------------------------------------------------------------------
class _GuestRow extends StatelessWidget {
  const _GuestRow({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AvatarCircle(
          color: cs.onSurfaceVariant.withValues(alpha: 0.2),
          child: Icon(Icons.person_outline, color: cs.onSurfaceVariant, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Guest',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Not signed in',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: () => context.push('/login'),
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Authenticated variant (user + admin)
// ---------------------------------------------------------------------------
class _AuthedRow extends StatelessWidget {
  const _AuthedRow({required this.user, required this.cs});

  final AuthUser user;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final initial = (user.displayName?.isNotEmpty == true
            ? user.displayName!
            : user.email ?? '?')
        .substring(0, 1)
        .toUpperCase();

    return Row(
      children: [
        _AvatarCircle(
          color: cs.primary,
          child: Text(
            initial,
            style: TextStyle(
              color: cs.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? user.email ?? 'User',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  if (user.isAdmin) ...[
                    _AdminBadge(cs: cs),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      user.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Admin badge chip
// ---------------------------------------------------------------------------
class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        'Admin',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04,
            ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared avatar circle container
// ---------------------------------------------------------------------------
class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }
}
