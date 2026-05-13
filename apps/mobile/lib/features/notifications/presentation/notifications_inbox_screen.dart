import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../domain/app_notification.dart';
import 'notification_tile.dart';
import 'notifications_providers.dart';

class NotificationsInboxScreen extends ConsumerWidget {
  const NotificationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inboxAsync = ref.watch(notificationsInboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        centerTitle: true,
        actions: [
          inboxAsync.maybeWhen(
            data: (data) {
              if (data.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllRead(ref, data.items),
                child: Text(l10n.notificationMarkAllRead),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsInboxProvider),
        child: inboxAsync.when(
          data: (data) {
            if (data.items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      l10n.notificationsEmpty,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: data.items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (context, i) {
                final n = data.items[i];
                return NotificationTile(
                  notification: n,
                  onTap: () => _onTap(context, ref, n),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text(l10n.notificationsLoadFailed)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllRead(WidgetRef ref, List<AppNotification> items) async {
    final unread = items.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unread.isEmpty) return;
    try {
      await ref.read(notificationsRepositoryProvider).markRead(unread);
    } finally {
      ref.invalidate(notificationsInboxProvider);
    }
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) async {
    if (!n.isRead) {
      try {
        await ref.read(notificationsRepositoryProvider).markRead([n.id]);
      } catch (_) {
        // Best-effort; ignore.
      }
      ref.invalidate(notificationsInboxProvider);
    }
    if (!context.mounted) return;
    if (n.reportId != null) {
      context.push('/report-detail/${n.reportId}');
    }
  }
}
