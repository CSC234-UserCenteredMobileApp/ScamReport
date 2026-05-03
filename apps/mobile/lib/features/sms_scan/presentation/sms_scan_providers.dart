import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/di/cache.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/sms_event_channel.dart';
import '../data/sms_scan_repository.dart';
import '../domain/sms_alert.dart';

final smsScanRepositoryProvider = Provider<SmsScanRepository>((ref) {
  return SmsScanRepository(
    http: ref.watch(httpClientProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

/// Processes incoming SMS events through /check.
/// Returns the new SmsAlert when verdict is scam/suspicious. Emits nothing for safe/unknown verdicts or when disabled.
final smsScannerProvider = StreamProvider<SmsAlert>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  if (settings == null || !settings.smsScanning) return const Stream.empty();

  final repo = ref.watch(smsScanRepositoryProvider);

  return ref.watch(smsEventChannelProvider.stream).asyncExpand((event) async* {
    final alert = await repo.processEvent(event);
    if (alert != null) yield alert;
  });
});

/// Local SMS scan results from drift, sorted newest-first.
/// Rebuilds whenever smsScannerProvider emits (new alert stored).
final smsAlertsProvider = FutureProvider<List<SmsAlert>>((ref) async {
  ref.watch(smsScannerProvider);
  return ref.watch(smsScanRepositoryProvider).listAlerts();
});
