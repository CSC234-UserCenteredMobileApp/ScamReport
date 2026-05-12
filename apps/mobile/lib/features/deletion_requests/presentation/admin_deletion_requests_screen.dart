import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/deletion_request.dart';
import 'deletion_requests_providers.dart';

class AdminDeletionRequestsScreen extends ConsumerWidget {
  const AdminDeletionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(deletionStatusFilterProvider);
    final statusKey = filter == null
        ? null
        : filter == DeletionRequestStatus.pending
            ? 'pending'
            : filter == DeletionRequestStatus.approved
                ? 'approved'
                : 'rejected';

    final requestsAsync = ref.watch(deletionRequestsProvider(statusKey));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deletion Requests'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _FilterChips(filter: filter, onChanged: (f) {
            ref.read(deletionStatusFilterProvider.notifier).state = f;
          }),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(deletionRequestsProvider);
              },
              child: requestsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('No requests.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _RequestCard(
                          request: items[i],
                          onRefresh: () =>
                              ref.invalidate(deletionRequestsProvider),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filter, required this.onChanged});

  final DeletionRequestStatus? filter;
  final void Function(DeletionRequestStatus?) onChanged;

  @override
  Widget build(BuildContext context) {
    final options = <DeletionRequestStatus?>[
      null,
      DeletionRequestStatus.pending,
      DeletionRequestStatus.approved,
      DeletionRequestStatus.rejected,
    ];
    const labels = <String>['All', 'Pending', 'Approved', 'Rejected'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(labels[i]),
                selected: filter == options[i],
                onSelected: (_) => onChanged(options[i]),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request, required this.onRefresh});

  final DeletionRequest request;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve deletion?'),
        content: Text(
            'Permanently delete ${widget.request.userHandle}\'s account and all related data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).extension<VerdictPalette>()!.scam.accent),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(deletionRequestsApiProvider);
      await api.approve(widget.request.id);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    String reason = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject deletion request'),
          content: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
            maxLength: 500,
            onChanged: (v) => reason = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || reason.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(deletionRequestsApiProvider);
      await api.reject(widget.request.id, reason.trim());
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verdict = theme.extension<VerdictPalette>()!;
    final req = widget.request;

    final Color statusColor;
    final String statusLabel;
    switch (req.status) {
      case DeletionRequestStatus.pending:
        statusColor = verdict.suspicious.accent;
        statusLabel = 'Pending';
      case DeletionRequestStatus.approved:
        statusColor = verdict.scam.accent;
        statusLabel = 'Approved';
      case DeletionRequestStatus.rejected:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusLabel = 'Rejected';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(req.userHandle,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Requested: ${_fmt(req.requestedAt)}  •  Due: ${_fmt(req.purgeDueAt)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (req.rejectionReason != null) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: ${req.rejectionReason}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (req.status == DeletionRequestStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _approve,
                      style: FilledButton.styleFrom(
                          backgroundColor: verdict.scam.accent),
                      child: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
