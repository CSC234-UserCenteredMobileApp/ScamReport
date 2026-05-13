import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feature_flags/feature_flags.dart';
import '../../check/data/check_api_client.dart';
import '../../check/domain/check_result.dart';
import '../domain/shared_payload.dart';
import 'share_intent_providers.dart';

/// Pass-through wrapper that listens to Android share intents and routes the
/// payload to /verdict pre-populated as a `CheckQuery(source: 'share')`.
///
/// Gated by the `enable_share_target` Remote Config flag — when disabled,
/// neither cold-start nor warm shares produce navigation. The widget renders
/// its [child] unchanged so it can wrap the bottom-nav shell builder.
class ShareIntentListener extends ConsumerStatefulWidget {
  const ShareIntentListener({
    super.key,
    required this.child,
    this.onShare,
  });

  final Widget child;

  /// Test seam. Defaults to `context.push('/verdict', extra: ...)`.
  final void Function(BuildContext, CheckQuery)? onShare;

  @override
  ConsumerState<ShareIntentListener> createState() =>
      _ShareIntentListenerState();
}

class _ShareIntentListenerState extends ConsumerState<ShareIntentListener> {
  bool _handledColdStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleColdStart());
  }

  Future<void> _handleColdStart() async {
    if (_handledColdStart || !mounted) return;
    _handledColdStart = true;
    if (!ref.read(featureFlagProvider(shareTargetFlagKey))) return;

    final service = ref.read(shareIntentServiceProvider);
    final payload = await service.initial();
    if (payload != null && mounted) {
      _route(payload);
    }
    await service.reset();
  }

  void _route(SharedPayload payload) {
    final query = CheckQuery(
      payload: payload.text,
      type: detectType(payload.text),
      source: 'share',
    );
    final handler = widget.onShare ??
        (BuildContext ctx, CheckQuery q) => ctx.push('/verdict', extra: q);
    handler(context, query);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<SharedPayload>>(shareIntentStreamProvider,
        (_, next) {
      final payload = next.valueOrNull;
      if (payload == null) return;
      if (!ref.read(featureFlagProvider(shareTargetFlagKey))) return;
      _route(payload);
    });
    return widget.child;
  }
}
