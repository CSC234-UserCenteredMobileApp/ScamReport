import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/admin_announcement.dart';
import 'announcement_editor_providers.dart';

class AdminAnnouncementsScreen extends ConsumerWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredAdminAnnouncementsProvider);
    final filter = ref.watch(announcementStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status filter chips
          _StatusFilterBar(current: filter),
          // List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(adminAnnouncementsListProvider),
              child: filteredAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('No announcements'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: items.length,
                    itemBuilder: (context, i) =>
                        _AnnouncementListTile(item: items[i]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/announcements/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatusFilterBar extends ConsumerWidget {
  const _StatusFilterBar({required this.current});

  final AdminAnnouncementStatus? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = <AdminAnnouncementStatus?>[
      null,
      AdminAnnouncementStatus.draft,
      AdminAnnouncementStatus.published,
      AdminAnnouncementStatus.unpublished,
    ];
    final labels = ['All', 'Draft', 'Published', 'Unpublished'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(filters.length, (i) {
          final selected = current == filters[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i]),
              selected: selected,
              onSelected: (_) {
                ref.read(announcementStatusFilterProvider.notifier).state =
                    filters[i];
              },
            ),
          );
        }),
      ),
    );
  }
}

class _AnnouncementListTile extends StatelessWidget {
  const _AnnouncementListTile({required this.item});

  final AdminAnnouncementListItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color statusColor;
    switch (item.status) {
      case AdminAnnouncementStatus.draft:
        statusColor = cs.surfaceContainerHighest;
      case AdminAnnouncementStatus.published:
        statusColor = cs.primaryContainer;
      case AdminAnnouncementStatus.unpublished:
        statusColor = cs.errorContainer;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/admin/announcements/${item.id}/edit'),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            _Chip(label: item.category.displayLabel),
            const SizedBox(width: 6),
            _Chip(
              label: item.status.name,
              color: statusColor,
            ),
          ],
        ),
        trailing: Text(
          _formatDate(item.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}
