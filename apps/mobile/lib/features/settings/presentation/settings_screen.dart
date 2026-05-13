import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/settings_state.dart';
import 'settings_providers.dart';

part '_account_card.dart';
part '_notifications_section.dart';
part '_preferences_section.dart';

// ---------------------------------------------------------------------------
// Skeleton placeholder — shared by loading states in part files.
// ---------------------------------------------------------------------------
class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Profile
            _AccountCard(user: user),
            const SizedBox(height: 24),

            // Appearance — language + theme
            _SectionLabel(context.l10n.settingsSectionAppearance),
            const SizedBox(height: 8),
            const _PreferencesSection(),
            const SizedBox(height: 24),

            // Alerts & Protection — push toggles + call screening + SMS scanning
            _SectionLabel(context.l10n.settingsSectionProtection),
            const SizedBox(height: 8),
            const _NotificationsSection(),
            const SizedBox(height: 24),

            // Admin tools — only visible to admins
            if (user?.isAdmin == true) ...[
              _SectionLabel(context.l10n.settingsSectionAdminTools),
              const SizedBox(height: 8),
              _AdminSection(),
              const SizedBox(height: 24),
            ],

            // Account — my reports + legal + sign out + delete
            _SectionLabel(context.l10n.settingsSectionAccount),
            const SizedBox(height: 8),
            _AccountSection(user: user),
            const SizedBox(height: 32),

            // Version footer
            Center(
              child: Text(
                'ScamReport v1.0 • KMUTT SIT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.06 * 14,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin tools section — announcements + deletion requests
// ---------------------------------------------------------------------------
class _AdminSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        children: [
          _NavTile(
            icon: Icons.campaign_outlined,
            title: context.l10n.manageAnnouncements,
            onTap: () => context.push('/admin/announcements'),
            isFirst: true,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _NavTile(
            icon: Icons.person_remove_outlined,
            title: context.l10n.deletionRequests,
            onTap: () => context.push('/admin/deletion-requests'),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account section — my reports + legal + sign out + delete
// ---------------------------------------------------------------------------
class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final isGuest = user == null;

    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        children: [
          // My reports — signed-in users only
          if (!isGuest) ...[
            _NavTile(
              icon: Icons.inbox_outlined,
              title: context.l10n.myReports,
              onTap: () => context.push('/my-reports'),
              isFirst: true,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],

          // Legal — always visible
          _NavTile(
            icon: Icons.lock_outline,
            title: context.l10n.privacyPolicy,
            onTap: () => context.push('/me/privacy'),
            isFirst: isGuest,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _NavTile(
            icon: Icons.article_outlined,
            title: context.l10n.termsOfService,
            onTap: () => context.push('/me/terms'),
            isLast: isGuest,
          ),

          // Destructive actions — signed-in users only
          if (!isGuest) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            const _SignOutTile(),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const _DeleteAccountExpansion(),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared nav tile
// ---------------------------------------------------------------------------
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
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
          title,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign out
// ---------------------------------------------------------------------------
class _SignOutTile extends StatelessWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final verdict = Theme.of(context).extension<VerdictPalette>()!;

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: ListTile(
        leading: Icon(Icons.logout, color: verdict.scam.accent, size: 22),
        title: Text(
          context.l10n.signOut,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: verdict.scam.accent,
                fontWeight: FontWeight.w500,
              ),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: () => _showSignOutDialog(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseAuth.instance.signOut();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).extension<VerdictPalette>()!.scam.accent,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Danger zone — collapsed by default; reveals delete account on expand.
// ---------------------------------------------------------------------------
class _DeleteAccountExpansion extends StatelessWidget {
  const _DeleteAccountExpansion();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.warning_amber_outlined,
              color: cs.onSurfaceVariant, size: 22),
          title: Text(
            context.l10n.settingsDangerZone,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
          ),
          iconColor: cs.onSurfaceVariant,
          collapsedIconColor: cs.onSurfaceVariant,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          children: const [
            Divider(height: 1, indent: 16, endIndent: 16),
            _DeleteAccountTile(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete account
// ---------------------------------------------------------------------------
class _DeleteAccountTile extends ConsumerWidget {
  const _DeleteAccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final verdict = Theme.of(context).extension<VerdictPalette>()!;

    ref.listen<AsyncValue<void>>(deleteAccountProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.deleteAccountFailed)),
        );
      }
    });

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      child: ListTile(
        leading: Icon(
          Icons.delete_forever_outlined,
          color: verdict.scam.accent,
          size: 22,
        ),
        title: Text(
          context.l10n.deleteAccount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: verdict.scam.accent,
                fontWeight: FontWeight.w500,
              ),
        ),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: () => _showDeleteDialog(context, ref),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountDialogTitle),
        content: Text(l10n.deleteAccountDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(deleteAccountProvider.notifier)
                  .requestDeletion();
            },
            style: FilledButton.styleFrom(
              backgroundColor:
                  Theme.of(ctx).extension<VerdictPalette>()!.scam.accent,
            ),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }
}
