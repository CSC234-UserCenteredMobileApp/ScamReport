import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../domain/entities/conversation.dart';
import 'ask_ai_providers.dart';

/// Side drawer listing the user's past Ask AI conversations. Tap to load,
/// long-press to delete. "New chat" resets the chat controller.
class ConversationsDrawer extends ConsumerWidget {
  const ConversationsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(conversationListProvider);
    final theme = Theme.of(context);
    final l = context.l10n;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.askAiPastChats,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const Key('askAiDrawerRefresh'),
                    icon: const Icon(Icons.refresh),
                    tooltip: l.askAiRefresh,
                    onPressed: () => ref.invalidate(conversationListProvider),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('askAiDrawerNewChat'),
                  icon: const Icon(Icons.add),
                  label: Text(l.askAiNewChat),
                  onPressed: () {
                    ref.read(askAiChatControllerProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: asyncList.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${l.askAiLoadFailed}\n$err',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l.askAiNoConversations,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    key: const Key('askAiConversationList'),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _ConversationTile(item: items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.item});
  final ConversationSummary item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return ListTile(
      title: Text(
        item.preview.isEmpty ? l.askAiNoPreview : item.preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatDate(item.lastMessageAt),
        style: theme.textTheme.bodySmall,
      ),
      trailing: item.linkedReportId != null
          ? Icon(Icons.flag_outlined, color: theme.colorScheme.primary)
          : null,
      onTap: () async {
        final navigator = Navigator.of(context);
        final repo = ref.read(askAiRepositoryProvider);
        await ref
            .read(askAiChatControllerProvider.notifier)
            .loadConversation(repo, item.id);
        if (navigator.mounted) navigator.pop();
      },
      onLongPress: () async {
        final messenger = ScaffoldMessenger.of(context);
        final repo = ref.read(askAiRepositoryProvider);
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(l.askAiDeletePrompt),
            content: Text(l.askAiDeleteIrreversible),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(l.askAiCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: Text(l.askAiDelete),
              ),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await repo.deleteConversation(item.id);
            ref.invalidate(conversationListProvider);
          } catch (_) {
            messenger.showSnackBar(SnackBar(content: Text(l.askAiDeleteFailed)));
          }
        }
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
