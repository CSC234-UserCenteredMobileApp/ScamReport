import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/notifications_api_client.dart';
import '../data/notifications_repository_impl.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

final notificationsApiClientProvider = Provider<NotificationsApiClient>((ref) {
  return NotificationsApiClient(
    ref.watch(httpClientProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(ref.watch(notificationsApiClientProvider));
});

final notificationsInboxProvider =
    FutureProvider<NotificationListData>((ref) async {
  return ref.watch(notificationsRepositoryProvider).listInbox();
});

final unreadCountProvider = Provider<int>((ref) {
  final inbox = ref.watch(notificationsInboxProvider);
  return inbox.maybeWhen(
    data: (d) => d.unreadCount,
    orElse: () => 0,
  );
});
