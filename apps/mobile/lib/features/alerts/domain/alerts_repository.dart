import 'alert.dart';

abstract class AlertsRepository {
  Future<List<Alert>> listAlerts({int limit = 20});
  Future<Alert> getAlert(String id);
}
