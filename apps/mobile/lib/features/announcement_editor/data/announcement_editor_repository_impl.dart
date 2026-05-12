import 'package:file_picker/file_picker.dart';

import '../domain/admin_announcement.dart';
import '../domain/announcement_editor_repository.dart';
import 'announcement_editor_api.dart';

class AnnouncementEditorRepositoryImpl implements AnnouncementEditorRepository {
  AnnouncementEditorRepositoryImpl(this._api);

  final AnnouncementEditorApi _api;

  @override
  Future<List<AdminAnnouncementListItem>> listAll() async {
    final raw = await _api.fetchAll();
    return raw.map((e) => _mapListItem(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<AdminAnnouncementDetail> getDetail(String id) async {
    final raw = await _api.fetchDetail(id);
    return _mapDetail(raw);
  }

  @override
  Future<AdminAnnouncementDetail> create({
    required String title,
    required String body,
    required AdminAnnouncementCategory category,
  }) async {
    final raw = await _api.postCreate({
      'title': title,
      'body': body,
      'category': category.apiValue,
    });
    return _mapDetail(raw);
  }

  @override
  Future<AdminAnnouncementDetail> update(
    String id, {
    String? title,
    String? body,
    AdminAnnouncementCategory? category,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (category != null) 'category': category.apiValue,
    };
    final raw = await _api.putUpdate(id, payload);
    return _mapDetail(raw);
  }

  @override
  Future<void> delete(String id) => _api.deleteAnnouncement(id);

  @override
  Future<AdminAnnouncementDetail> publish(String id, {required bool pushToFcm}) async {
    final raw = await _api.postPublish(id, pushToFcm: pushToFcm);
    return _mapDetail(raw);
  }

  @override
  Future<AdminAnnouncementDetail> unpublish(String id) async {
    await _api.postUnpublish(id);
    return getDetail(id); // refetch full detail
  }

  AdminAnnouncementListItem _mapListItem(Map<String, dynamic> m) {
    return AdminAnnouncementListItem(
      id: m['id'] as String,
      slug: m['slug'] as String,
      title: m['title'] as String,
      category: _parseCategory(m['category'] as String),
      status: _parseStatus(m['status'] as String),
      createdAt: DateTime.parse(m['createdAt'] as String),
      publishedAt: m['publishedAt'] != null
          ? DateTime.parse(m['publishedAt'] as String)
          : null,
    );
  }

  AdminAnnouncementDetail _mapDetail(Map<String, dynamic> m) {
    final rawAttachments = m['attachments'] as List<dynamic>? ?? [];
    return AdminAnnouncementDetail(
      id: m['id'] as String,
      slug: m['slug'] as String,
      title: m['title'] as String,
      body: m['body'] as String,
      category: _parseCategory(m['category'] as String),
      status: _parseStatus(m['status'] as String),
      createdAt: DateTime.parse(m['createdAt'] as String),
      updatedAt: DateTime.parse(m['updatedAt'] as String),
      publishedAt: m['publishedAt'] != null
          ? DateTime.parse(m['publishedAt'] as String)
          : null,
      pushedToFcmAt: m['pushedToFcmAt'] != null
          ? DateTime.parse(m['pushedToFcmAt'] as String)
          : null,
      authorId: m['authorId'] as String?,
      attachments: rawAttachments.map((a) {
        final am = a as Map<String, dynamic>;
        return AnnouncementAttachment(
          id: am['id'] as String,
          storagePath: am['storagePath'] as String,
          kind: am['kind'] as String,
          mimeType: am['mimeType'] as String,
          sizeBytes: (am['sizeBytes'] as num).toInt(),
          sortOrder: (am['sortOrder'] as num).toInt(),
        );
      }).toList(),
    );
  }

  @override
  Future<AnnouncementAttachment> uploadAttachment(
      String announcementId, PlatformFile file) async {
    final raw = await _api.postAttachment(announcementId, file);
    return AnnouncementAttachment(
      id: raw['id'] as String,
      storagePath: raw['storagePath'] as String,
      kind: raw['kind'] as String,
      mimeType: raw['mimeType'] as String,
      sizeBytes: (raw['sizeBytes'] as num).toInt(),
      sortOrder: (raw['sortOrder'] as num).toInt(),
    );
  }

  @override
  Future<void> deleteAttachment(
      String announcementId, String attachmentId) async {
    await _api.deleteAttachment(announcementId, attachmentId);
  }

  AdminAnnouncementStatus _parseStatus(String s) => switch (s) {
        'draft' => AdminAnnouncementStatus.draft,
        'published' => AdminAnnouncementStatus.published,
        'unpublished' => AdminAnnouncementStatus.unpublished,
        _ => AdminAnnouncementStatus.draft,
      };

  AdminAnnouncementCategory _parseCategory(String s) => switch (s) {
        'fraud_alert' => AdminAnnouncementCategory.fraudAlert,
        'tips' => AdminAnnouncementCategory.tips,
        'platform_update' => AdminAnnouncementCategory.platformUpdate,
        _ => AdminAnnouncementCategory.tips,
      };
}
