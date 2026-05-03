import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../home/domain/recent_alert.dart';
import '../../sms_scan/presentation/sms_scan_providers.dart';
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
  return ref.watch(alertsRepositoryProvider).listAlerts();
});

/// Fetches a single announcement by id.
final alertDetailProvider =
    FutureProvider.family<Alert, String>((ref, id) async {
  return ref.watch(alertsRepositoryProvider).getAlert(id);
});

// Filter state --------------------------------------------------------------
/// Currently selected category filter; `null` means "All".
final selectedCategoryProvider = StateProvider<AlertCategory?>((ref) => null);

/// Alerts filtered by [selectedCategoryProvider].
/// - `null` (All): merges API alerts + SMS alerts, sorted by publishedAt desc.
/// - `AlertCategory.smsAlert`: returns only drift-sourced SMS alerts.
/// - Other category: API alerts filtered to that category only.
final filteredAlertsProvider = Provider<AsyncValue<List<Alert>>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final alertsAsync = ref.watch(alertsProvider);
  final smsAsync = ref.watch(smsAlertsProvider);

  if (category == AlertCategory.smsAlert) {
    return smsAsync.whenData(
      (smsAlerts) => smsAlerts.map(Alert.fromSmsAlert).toList(),
    );
  }

  return alertsAsync.whenData((alerts) {
    if (category == null) {
      final smsAlerts =
          smsAsync.valueOrNull?.map(Alert.fromSmsAlert).toList() ?? [];
      final combined = [...alerts, ...smsAlerts]
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return combined;
    }
    return alerts.where((a) => a.category == category).toList();
  });
});
