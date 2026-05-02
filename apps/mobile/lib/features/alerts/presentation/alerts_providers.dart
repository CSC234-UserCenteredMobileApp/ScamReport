import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../home/domain/recent_alert.dart';
import '../data/alerts_api_client.dart';
import '../data/alerts_repository_impl.dart';
import '../domain/alert.dart';
import '../domain/alerts_repository.dart';

// Repository providers ------------------------------------------------------
final alertsApiClientProvider = Provider<AlertsApiClient>((ref) {
  return AlertsApiClient(ref.watch(httpClientProvider));
});

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepositoryImpl(ref.watch(alertsApiClientProvider));
});

// Data providers ------------------------------------------------------------
/// Fetches the full list of announcements.
final alertsProvider = FutureProvider<List<Alert>>((ref) async {
  return ref.read(alertsRepositoryProvider).listAlerts();
});

/// Fetches a single announcement by id.
final alertDetailProvider =
    FutureProvider.family<Alert, String>((ref, id) async {
  return ref.read(alertsRepositoryProvider).getAlert(id);
});

// Filter state --------------------------------------------------------------
/// Currently selected category filter; `null` means "All".
final selectedCategoryProvider = StateProvider<AlertCategory?>((ref) => null);

/// Alerts filtered by [selectedCategoryProvider].
final filteredAlertsProvider = Provider<AsyncValue<List<Alert>>>((ref) {
  final alertsAsync = ref.watch(alertsProvider);
  final category = ref.watch(selectedCategoryProvider);
  return alertsAsync.whenData(
    (alerts) => category == null
        ? alerts
        : alerts.where((a) => a.category == category).toList(),
  );
});
