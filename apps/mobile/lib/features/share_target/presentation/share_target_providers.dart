import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/share_intent_service.dart';

export '../../../core/feature_flags/feature_flags.dart' show featureFlagProvider;

final shareIntentServiceProvider = Provider.autoDispose<ShareIntentService>((ref) {
  final svc = ShareIntentService();
  ref.onDispose(svc.dispose);
  return svc;
});
