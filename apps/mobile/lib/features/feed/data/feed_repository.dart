import '../../home/domain/recent_report.dart';
import 'feed_api.dart';

class FeedRepository {
  FeedRepository(this._api);

  final FeedApi _api;

  Future<List<RecentReport>> getReports() async {
    final raw = await _api.fetchReports();
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
}
