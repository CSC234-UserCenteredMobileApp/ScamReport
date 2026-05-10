import '../../home/domain/recent_report.dart';
import '../domain/scam_type_item.dart';
import 'search_api.dart';

class SearchRepository {
  SearchRepository(this._api);

  final SearchApi _api;

  Future<List<RecentReport>> searchReports({
    String? q,
    List<String> scamTypeCodes = const [],
    String sortBy = 'latest',
  }) async {
    final raw = await _api.searchReports(
      q: q,
      scamTypeCodes: scamTypeCodes,
      sortBy: sortBy,
    );
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

  Future<List<ScamTypeItem>> getScamTypes() async {
    final raw = await _api.fetchScamTypes();
    return raw.map((item) {
      final map = item as Map<String, dynamic>;
      return ScamTypeItem(
        code: map['code'] as String,
        labelEn: map['labelEn'] as String,
        labelTh: map['labelTh'] as String,
        displayOrder: map['displayOrder'] as int,
      );
    }).toList();
  }
}
