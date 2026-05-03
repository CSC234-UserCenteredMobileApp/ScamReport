import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../../alerts/presentation/alerts_providers.dart';
import '../../home/domain/recent_alert.dart';
import '../domain/sms_alert.dart';
import 'sms_scan_providers.dart';

/// Wraps the shell route builder. Listens for new SMS scan results and shows
/// an [OverlayEntry] banner at the top of the screen.
class SmsAlertOverlayWrapper extends ConsumerStatefulWidget {
  const SmsAlertOverlayWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SmsAlertOverlayWrapper> createState() =>
      _SmsAlertOverlayWrapperState();
}

class _SmsAlertOverlayWrapperState
    extends ConsumerState<SmsAlertOverlayWrapper> {
  OverlayEntry? _entry;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    ref.listen(smsScannerProvider, (_, next) {
      final alert = next.valueOrNull;
      if (alert != null) _showBanner(context, alert);
    });
    return widget.child;
  }

  void _showBanner(BuildContext context, SmsAlert alert) {
    _timer?.cancel();
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => SmsAlertBanner(
        alert: alert,
        onDismiss: _dismiss,
        onView: () {
          _dismiss();
          ref.read(selectedCategoryProvider.notifier).state =
              AlertCategory.smsAlert;
          context.go('/alerts');
        },
      ),
    );
    Overlay.of(context).insert(_entry!);
    _timer = Timer(const Duration(seconds: 6), _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _dismiss();
    super.dispose();
  }
}

/// Stateless banner widget rendered inside an OverlayEntry.
class SmsAlertBanner extends StatelessWidget {
  const SmsAlertBanner({
    super.key,
    required this.alert,
    required this.onDismiss,
    required this.onView,
  });

  final SmsAlert alert;
  final VoidCallback onDismiss;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final verdictPalette = Theme.of(context).extension<VerdictPalette>()!;
    final isScam = alert.verdict == 'scam';
    final bg = isScam ? verdictPalette.scam.bg : verdictPalette.suspicious.bg;
    final fg = isScam ? verdictPalette.scam.fg : verdictPalette.suspicious.fg;
    final title =
        isScam ? context.l10n.smsScanScamTitle : context.l10n.smsScanTitle;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.sms_failed_outlined, color: fg, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      alert.senderMasked,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      alert.bodyExcerpt,
                      style: TextStyle(color: fg, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  foregroundColor: fg,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(context.l10n.view),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: fg, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
