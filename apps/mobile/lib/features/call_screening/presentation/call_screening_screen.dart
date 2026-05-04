import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/blocked_call.dart';
import 'call_screening_providers.dart';
import '_permission_card.dart';

class CallScreeningScreen extends ConsumerWidget {
  const CallScreeningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sdkAsync = ref.watch(callScreeningSdkVersionProvider);
    final isDefaultAsync = ref.watch(callScreeningIsDefaultProvider);
    final enabled = ref.watch(callScreeningEnabledProvider);
    final blockedAsync = ref.watch(blockedCallsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Call Screening')),
      body: sdkAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (sdk) {
          if (sdk < 29) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Call screening requires Android 10 or later.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView(
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
      title: const Text('Call Screening'),
      subtitle: const Text('Automatically silence known scam callers'),
      value: enabled,
      onChanged: (v) async {
        ref.read(callScreeningEnabledProvider.notifier).state = v;
        if (v) {
          try {
            final repo =
                await ref.read(callScreeningRepositoryProvider.future);
            await repo.syncPhoneList();
          } catch (_) {
            // sync failure is non-fatal; cached data still used
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
      return const Text(
        'No blocked calls yet.',
        textAlign: TextAlign.center,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${calls.length} call${calls.length == 1 ? '' : 's'} blocked',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...calls.map(
          (c) => ListTile(
            leading: const Icon(Icons.block),
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
