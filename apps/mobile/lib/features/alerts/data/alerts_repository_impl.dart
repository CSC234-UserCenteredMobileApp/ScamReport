import '../domain/alert.dart';
import '../domain/alerts_repository.dart';
import '../../home/domain/recent_alert.dart';
import 'alerts_api_client.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl(this._api);

  final AlertsApiClient _api;

  @override
  Future<List<Alert>> listAlerts({int limit = 20}) async {
    final raw = await _api.fetchAlerts(limit: limit);
    return raw.map((item) => _mapAlert(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<Alert> getAlert(String id) async {
    final raw = await _api.fetchAlert(id);
    return _mapAlert(raw);
  }

  Alert _mapAlert(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] as String,
      title: map['title'] as String,
      excerpt: map['excerpt'] as String,
      body: (map['body'] as String?) ?? '',
      category: _parseCategory(map['category'] as String),
      publishedAt: DateTime.parse(map['publishedAt'] as String),
      slug: (map['slug'] as String?) ?? '',
    );
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
        throw ArgumentError('Unknown AlertCategory value: $value');
    }
  }
}
