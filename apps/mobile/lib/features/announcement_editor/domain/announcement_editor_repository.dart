import 'package:file_picker/file_picker.dart';

import 'admin_announcement.dart';

abstract class AnnouncementEditorRepository {
  Future<List<AdminAnnouncementListItem>> listAll();
  Future<AdminAnnouncementDetail> getDetail(String id);
  Future<AdminAnnouncementDetail> create({
    required String title,
    required String body,
    required AdminAnnouncementCategory category,
  });
  Future<AdminAnnouncementDetail> update(
    String id, {
    String? title,
    String? body,
    AdminAnnouncementCategory? category,
  });
  Future<void> delete(String id);
  Future<AdminAnnouncementDetail> publish(String id, {required bool pushToFcm});
  Future<AdminAnnouncementDetail> unpublish(String id);
  Future<AnnouncementAttachment> uploadAttachment(
      String announcementId, PlatformFile file);
  Future<void> deleteAttachment(String announcementId, String attachmentId);
}
