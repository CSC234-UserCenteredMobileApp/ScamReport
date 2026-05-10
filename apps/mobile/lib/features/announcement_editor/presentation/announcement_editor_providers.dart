import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/auth.dart';
import '../data/announcement_editor_api.dart';
import '../data/announcement_editor_repository_impl.dart';
import '../domain/admin_announcement.dart';
import '../domain/announcement_editor_repository.dart';

final announcementEditorApiProvider = Provider<AnnouncementEditorApi>((ref) {
  return AnnouncementEditorApi(
    ref.watch(httpClientProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final announcementEditorRepositoryProvider =
    Provider<AnnouncementEditorRepository>((ref) {
  return AnnouncementEditorRepositoryImpl(
    ref.watch(announcementEditorApiProvider),
  );
});

final adminAnnouncementsListProvider =
    FutureProvider<List<AdminAnnouncementListItem>>((ref) {
  return ref.watch(announcementEditorRepositoryProvider).listAll();
});

final adminAnnouncementDetailProvider =
    FutureProvider.family<AdminAnnouncementDetail, String>((ref, id) {
  return ref.watch(announcementEditorRepositoryProvider).getDetail(id);
});

final announcementStatusFilterProvider =
    StateProvider<AdminAnnouncementStatus?>((ref) => null);

final filteredAdminAnnouncementsProvider =
    Provider<AsyncValue<List<AdminAnnouncementListItem>>>((ref) {
  final listAsync = ref.watch(adminAnnouncementsListProvider);
  final filter = ref.watch(announcementStatusFilterProvider);
  return listAsync.whenData(
    (items) => filter == null
        ? items
        : items.where((i) => i.status == filter).toList(),
  );
});
