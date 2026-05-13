import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../domain/app_notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    final colors = _colorsFor(notification.kind, verdict);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  Icon(_iconFor(notification.kind), color: colors.fg, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _ageLabel(context.l10n, notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  VerdictColors _colorsFor(NotificationKind kind, VerdictPalette p) {
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

String _ageLabel(AppLocalizations l10n, DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return l10n.notificationTimeJustNow;
  if (diff.inHours < 1) return l10n.notificationTimeMinutes(diff.inMinutes);
  if (diff.inDays < 1) return l10n.notificationTimeHours(diff.inHours);
  return l10n.notificationTimeDays(diff.inDays);
}
