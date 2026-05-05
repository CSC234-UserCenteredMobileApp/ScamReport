import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/l10n.dart';
import '../domain/blocked_call.dart';
import 'call_screening_providers.dart';
import '_permission_card.dart';

class CallScreeningScreen extends ConsumerWidget {
  const CallScreeningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdkAsync = ref.watch(callScreeningSdkVersionProvider);
    final isDefaultAsync = ref.watch(callScreeningIsDefaultProvider);
    final enabledAsync = ref.watch(callScreeningEnabledProvider);
    final blockedAsync = ref.watch(blockedCallsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.callScreeningTitle)),
      body: sdkAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (sdk) {
          if (sdk < 29) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.callScreeningUnsupported,
                textAlign: TextAlign.center,
              ),
            );
          }

          final enabled = enabledAsync.valueOrNull ?? false;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(blockedCallsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _EnableTile(enabled: enabled),
                if (enabled) ...[
                  const SizedBox(height: 16),
                  isDefaultAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (isDefault) =>
                        isDefault ? const SizedBox.shrink() : const PermissionCard(),
                  ),
                  const SizedBox(height: 16),
                  blockedAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (calls) => _BlockedCallsSection(calls: calls),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EnableTile extends ConsumerWidget {
  const _EnableTile({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      title: Text(context.l10n.callScreeningTitle),
      subtitle: Text(context.l10n.callScreeningSubtitle),
      value: enabled,
      onChanged: (v) async {
        try {
          await ref
              .read(callScreeningEnabledProvider.notifier)
              .setEnabled(v);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.callScreeningSyncFailed)),
            );
          }
        }
      },
    );
  }
}

class _BlockedCallsSection extends StatelessWidget {
  const _BlockedCallsSection({required this.calls});

  final List<BlockedCall> calls;

  @override
  Widget build(BuildContext context) {
    if (calls.isEmpty) {
      return Text(
        context.l10n.callScreeningNoBlocked,
        textAlign: TextAlign.center,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.callScreeningBlockedCount(calls.length),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...calls.map(
          (c) => ListTile(
            leading: const Icon(Icons.warning_amber_outlined),
            title: Text(c.number),
            subtitle: Text(_formatDate(c.blockedAt)),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
