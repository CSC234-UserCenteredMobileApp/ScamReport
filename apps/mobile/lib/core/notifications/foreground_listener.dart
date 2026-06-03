import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/domain/app_notification.dart';
import '../../features/notifications/presentation/notifications_providers.dart';
import '../../l10n/l10n.dart';
import '../di/messaging.dart';
import '../theme/app_theme.dart';

// Drop this widget below MaterialApp.router so the app gets:
//   1. A MaterialBanner on foreground FCM messages with a View action that
//      deep-links to /report-detail/<id> and marks the inbox row read.
//   2. The same deep-link routing for taps on a system-tray push that opens
//      the app from background (`onMessageOpenedApp`) or from terminated
//      (`getInitialMessage`).
//
// Inbox provider is invalidated on every event so the inbox is fresh on
// next open without a manual pull-to-refresh.
class ForegroundNotificationListener extends ConsumerStatefulWidget {
  const ForegroundNotificationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ForegroundNotificationListener> createState() =>
      _ForegroundNotificationListenerState();
}

class _ForegroundNotificationListenerState
    extends ConsumerState<ForegroundNotificationListener> {
  @override
  Widget build(BuildContext context) {
    ref.listen(fcmForegroundMessagesProvider, (_, next) {
      next.whenData((message) => _handleForeground(context, message));
    });
    // Tap-on-push + cold-start notification, via DI providers (not the
    // FirebaseMessaging statics) so errors stay contained and tests can
    // override them.
    ref.listen(fcmOpenedAppMessagesProvider, (_, next) {
      next.whenData(_handleTap);
    });
    ref.listen(fcmInitialMessageProvider, (_, next) {
      next.whenData((msg) {
        if (msg != null) _handleTap(msg);
      });
    });
    return widget.child;
  }

  void _handleForeground(BuildContext context, RemoteMessage message) {
    ref.invalidate(notificationsInboxProvider);

    final data = message.data;
    final kind = NotificationKind.fromWire(data['kind'] as String? ?? '');
    final reportId = data['reportId'] as String?;
    final notificationId = data['notificationId'] as String?;
    final l10n = context.l10n;
    final notif = message.notification;
    final title = notif?.title ?? _fallbackTitle(l10n, kind);
    final body = notif?.body ?? '';

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>();
    final palette = _paletteFor(kind, verdict);

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor:
            palette?.bg ?? theme.colorScheme.surfaceContainerHighest,
        leading: Icon(_iconFor(kind), color: palette?.fg),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette?.fg,
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(body, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              _markReadAndRoute(context, reportId, notificationId);
            },
            child: Text(l10n.notificationView),
          ),
        ],
      ),
    );
  }

  void _handleTap(RemoteMessage message) {
    ref.invalidate(notificationsInboxProvider);
    final data = message.data;
    final reportId = data['reportId'] as String?;
    final notificationId = data['notificationId'] as String?;
    if (!mounted) return;
    _markReadAndRoute(context, reportId, notificationId);
  }

  void _markReadAndRoute(
    BuildContext context,
    String? reportId,
    String? notificationId,
  ) {
    if (notificationId != null && notificationId.isNotEmpty) {
      ref
          .read(notificationsRepositoryProvider)
          .markRead([notificationId]).catchError((_) => 0);
    }
    if (reportId == null || reportId.isEmpty) return;
    if (!context.mounted) return;
    context.push('/report-detail/$reportId');
  }

  String _fallbackTitle(AppLocalizations l10n, NotificationKind kind) {
    switch (kind) {
      case NotificationKind.reportVerified:
        return l10n.notificationVerifiedTitle;
      case NotificationKind.reportRejected:
        return l10n.notificationRejectedTitle;
      case NotificationKind.reportFlagged:
        return l10n.notificationFlaggedTitle;
      case NotificationKind.unknown:
        return l10n.notificationsTitle;
    }
  }

  VerdictColors? _paletteFor(NotificationKind kind, VerdictPalette? p) {
    if (p == null) return null;
    switch (kind) {
      case NotificationKind.reportVerified:
        return p.safe;
      case NotificationKind.reportRejected:
        return p.scam;
      case NotificationKind.reportFlagged:
        return p.suspicious;
      case NotificationKind.unknown:
        return p.unknown;
    }
  }

  IconData _iconFor(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.reportVerified:
        return Icons.verified_rounded;
      case NotificationKind.reportRejected:
        return Icons.cancel_rounded;
      case NotificationKind.reportFlagged:
        return Icons.flag_rounded;
      case NotificationKind.unknown:
        return Icons.notifications_rounded;
    }
  }
}
