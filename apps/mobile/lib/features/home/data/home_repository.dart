import '../domain/home_stats.dart';
import '../domain/recent_alert.dart';
import '../domain/recent_report.dart';
import 'home_api.dart';

class HomeRepository {
  HomeRepository(this._api);

  final HomeApi _api;

  Future<HomeStats> getStats() async {
    final json = await _api.fetchStats();
    final data = json['data'] as Map<String, dynamic>;
    return HomeStats(
      verifiedTotal: data['verifiedTotal'] as int,
      newThisWeek: data['newThisWeek'] as int,
      topScamType: data['topScamType'] as String,
    );
  }

  Future<List<RecentAlert>> getRecentAlerts() async {
    final raw = await _api.fetchRecentAlerts();
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      return RecentAlert(
        id: map['id'] as String,
        title: map['title'] as String,
        category: _parseCategory(map['category'] as String),
        publishedAt: DateTime.parse(map['publishedAt'] as String),
      );
    }).toList();
  }

  Future<List<RecentReport>> getRecentReports() async {
    final raw = await _api.fetchRecentReports();
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      return RecentReport(
        id: map['id'] as String,
        title: map['title'] as String,
        excerpt: map['excerpt'] as String,
        scamTypeCode: map['scamTypeCode'] as String,
        scamTypeLabelEn: map['scamTypeLabelEn'] as String,
        scamTypeLabelTh: map['scamTypeLabelTh'] as String,
        verifiedAt: DateTime.parse(map['verifiedAt'] as String),
        reportCount: map['reportCount'] as int,
      );
    }).toList();
  }

  AlertCategory _parseCategory(String value) {
    switch (value) {
      case 'fraud_alert':
        return AlertCategory.fraudAlert;
      case 'tips':
        return AlertCategory.tips;
      case 'platform_update':
        return AlertCategory.platformUpdate;
      default:
        // Throw on unknown values so API drift is surfaced immediately.
        throw ArgumentError('Unknown AlertCategory value: $value');
    }
  }
}
