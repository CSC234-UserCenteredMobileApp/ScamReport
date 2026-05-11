enum AdminAnnouncementStatus { draft, published, unpublished }

enum AdminAnnouncementCategory { fraudAlert, tips, platformUpdate }

extension AdminAnnouncementCategoryLabel on AdminAnnouncementCategory {
  String get apiValue => switch (this) {
        AdminAnnouncementCategory.fraudAlert => 'fraud_alert',
        AdminAnnouncementCategory.tips => 'tips',
        AdminAnnouncementCategory.platformUpdate => 'platform_update',
      };

  String get displayLabel => switch (this) {
        AdminAnnouncementCategory.fraudAlert => 'Fraud Alert',
        AdminAnnouncementCategory.tips => 'Tips',
        AdminAnnouncementCategory.platformUpdate => 'Platform Update',
      };
}

class AdminAnnouncementListItem {
  const AdminAnnouncementListItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.category,
    required this.status,
    required this.createdAt,
    this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final AdminAnnouncementCategory category;
  final AdminAnnouncementStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
}

class AdminAnnouncementDetail {
  const AdminAnnouncementDetail({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.pushedToFcmAt,
    this.authorId,
  });

  final String id;
  final String slug;
  final String title;
  final String body;
  final AdminAnnouncementCategory category;
  final AdminAnnouncementStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? pushedToFcmAt;
  final String? authorId;
}
