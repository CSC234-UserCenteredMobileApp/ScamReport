import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../data/attachment_picker.dart';
import '../domain/entities/ai_draft.dart';
import '../domain/entities/chat_attachment.dart';
import '../domain/entities/chat_message.dart';
import '../domain/failures.dart';
import 'ask_ai_providers.dart';
import 'conversations_drawer.dart';
import 'widgets/attachment_chip.dart';
import 'widgets/consent_card.dart';
import 'widgets/draft_editor_sheet.dart';

/// Ask AI conversational chat screen (P-09 / FR-4.x). Text-only in v1;
/// attachments + inline consent + draft editor land in PR-4 / PR-5.
class AskAiScreen extends ConsumerStatefulWidget {
  const AskAiScreen({super.key});

  @override
  ConsumerState<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends ConsumerState<AskAiScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _controller.text;
    final state = ref.read(askAiChatControllerProvider);
    // Allow image-only sends: skip the early return when staged attachments
    // are present.
    if (content.trim().isEmpty && state.stagedAttachments.isEmpty) return;
    _controller.clear();
    await ref.read(askAiChatControllerProvider.notifier).sendMessage(content);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openEditor(AiDraft current) async {
    final state = ref.read(askAiChatControllerProvider);
    final updated = await showModalBottomSheet<DraftEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraftEditorSheet(
        initial: current,
        initialEvidence: state.effectiveEvidence,
      ),
    );
    if (updated != null) {
      ref
          .read(askAiChatControllerProvider.notifier)
          .updateDraft(updated.draft, evidence: updated.evidence);
    }
  }

  Future<void> _askRedraft() async {
    final l = context.l10n;
    await ref
        .read(askAiChatControllerProvider.notifier)
        .sendMessage(l.askAiAskRedraftPrompt);
  }

  Future<void> _pickAttachment() async {
    final picker = ref.read(attachmentPickerProvider);
    final controller = ref.read(askAiChatControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      final picked = await showModalBottomSheet<StagedAttachment>(
        context: context,
        builder: (sheetCtx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l.askAiAttachCamera),
                onTap: () async {
                  final a = await picker.pickFromCamera();
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop(a);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l.askAiAttachGallery),
                onTap: () async {
                  final a = await picker.pickFromGallery();
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop(a);
                },
              ),
            ],
          ),
        ),
      );
      if (picked != null) controller.stageAttachment(picked);
    } on AskAiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(askAiChatControllerProvider);
    final theme = Theme.of(context);

    final l = context.l10n;
    return Scaffold(
      drawer: const ConversationsDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.askAiTitle),
            const SizedBox(width: 8),
            const _BetaBadge(),
          ],
        ),
        actions: [
          // Persistent "View draft" affordance — visible whenever an active
          // draft exists so the user can re-open the editor without scrolling
          // back to the AI bubble that produced the draft. iter-5 UX.
          IconButton(
            key: const Key('askAiViewDraft'),
            tooltip: l.askAiViewDraft,
            icon: const Icon(Icons.description_outlined),
            color: state.activeDraft != null && !state.isSubmitting
                ? theme.colorScheme.primary
                : theme.disabledColor,
            onPressed: state.activeDraft != null && !state.isSubmitting
                ? () => _openEditor(state.activeDraft!)
                : null,
          ),
          IconButton(
            key: const Key('askAiNewChat'),
            tooltip: l.askAiNewChat,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () =>
                ref.read(askAiChatControllerProvider.notifier).reset(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    key: const Key('askAiMessageList'),
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: state.messages.length +
                        (state.isSending ? 1 : 0) +
                        (state.canOfferReport ? 1 : 0) +
                        (state.submittedReportId != null ? 1 : 0),
                    itemBuilder: (context, i) {
                      final base = state.messages.length;
                      if (i < base) {
                        return _MessageBubble(message: state.messages[i]);
                      }
                      var offset = i - base;
                      if (state.isSending && offset == 0) {
                        return const _TypingIndicator();
                      }
                      if (state.isSending) offset--;
                      if (state.canOfferReport && offset == 0) {
                        return ConsentCard(
                          draft: state.activeDraft!,
                          isSubmitting: state.isSubmitting,
                          onEdit: () => _openEditor(state.activeDraft!),
                          onAskRedraft: () => _askRedraft(),
                          onSubmit: () => ref
                              .read(askAiChatControllerProvider.notifier)
                              .submitActiveDraft(),
                        );
                      }
                      if (state.canOfferReport) offset--;
                      if (state.submittedReportId != null && offset == 0) {
                        return _SubmittedBanner(
                          reportId: state.submittedReportId!,
                          onOpen: () => context.go('/my-reports'),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
          if (state.error != null)
            Container(
              width: double.infinity,
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatSendError(state.error!, l.askAiSendFailed),
                      style:
                          TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  if (state.lastFailedAttempt != null)
                    TextButton(
                      key: const Key('askAiRetryButton'),
                      onPressed: () => ref
                          .read(askAiChatControllerProvider.notifier)
                          .retryLastFailedSend(),
                      child: Text(
                        l.askAiRetry,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                if (state.stagedAttachments.isNotEmpty)
                  RepaintBoundary(
                    child: SizedBox(
                      key: const Key('askAiStagedRow'),
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: state.stagedAttachments.length,
                        itemBuilder: (_, i) {
                          final s = state.stagedAttachments[i];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            // Stable ValueKey on bytes identity so Flutter
                            // reuses the same _AttachmentChipState (and its
                            // hoisted MemoryImage) across rebuilds.
                            child: AttachmentChip(
                              key: ValueKey(s.bytes),
                              bytes: s.bytes,
                              mimeType: s.mimeType,
                              onRemove: () => ref
                                  .read(askAiChatControllerProvider.notifier)
                                  .removeStagedAttachment(i),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        key: const Key('askAiAttachButton'),
                        onPressed: state.isSending ||
                                state.stagedAttachments.length >=
                                    maxAttachmentsPerMessage
                            ? null
                            : _pickAttachment,
                        icon: const Icon(Icons.attach_file_rounded),
                        tooltip: l.askAiAttach,
                      ),
                      Expanded(
                        child: TextField(
                          key: const Key('askAiComposer'),
                          controller: _controller,
                          enabled: !state.isSending,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 4000,
                          decoration: InputDecoration(
                            hintText: l.askAiComposerHint,
                            counterText: '',
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: const Key('askAiSendButton'),
                        onPressed: state.isSending ? null : _send,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Translate a thrown sendMessage error into a single-line banner string.
/// Surfaces the underlying failure message instead of a generic l10n line so
/// network / server / validation problems are visible on-device.
String _formatSendError(Object error, String fallback) {
  if (error is AskAiFailure) {
    final detail = error.message.trim();
    return detail.isEmpty ? fallback : '$fallback: $detail';
  }
  // Last resort — keep the visible message short.
  final s = error.toString();
  return s.length > 200 ? '$fallback: ${s.substring(0, 200)}…' : '$fallback: $s';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.askAiWelcomeTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(l.askAiWelcomeBody, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.askAiDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fg =
        isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final hasContent = message.content.trim().isNotEmpty;
    final hasAttachments = message.attachments.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: align,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasAttachments)
                  Padding(
                    padding: EdgeInsets.only(bottom: hasContent ? 8 : 0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final a in message.attachments)
                          _BubbleAttachment(attachment: a, onPrimary: isUser),
                      ],
                    ),
                  ),
                if (hasContent)
                  Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleAttachment extends StatefulWidget {
  const _BubbleAttachment({required this.attachment, required this.onPrimary});
  final ChatAttachment attachment;
  final bool onPrimary;

  @override
  State<_BubbleAttachment> createState() => _BubbleAttachmentState();
}

class _BubbleAttachmentState extends State<_BubbleAttachment> {
  // Hoisted MemoryImage so optimistic bubbles don't redecode the file on
  // every rebuild during the in-flight send (same pattern AttachmentChip
  // uses in iter-2).
  late final ImageProvider? _localProvider =
      widget.attachment.localBytes != null &&
              widget.attachment.mimeType.startsWith('image/')
          ? MemoryImage(widget.attachment.localBytes!)
          : null;

  @override
  void dispose() {
    _localProvider?.evict();
    super.dispose();
  }

  bool get _isImage => widget.attachment.mimeType.startsWith('image/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = widget.attachment.signedUrl;
    final placeholder = Container(
      width: 160,
      height: 160,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        _isImage ? Icons.broken_image_outlined : Icons.picture_as_pdf_outlined,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    // Optimistic bubble — render local bytes via the hoisted provider.
    if (_localProvider != null) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
            image: _localProvider,
            width: 160,
            height: 160,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        ),
      );
    }

    if (_isImage && url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 160,
              height: 160,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.onPrimary
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                ),
              ),
            );
          },
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: placeholder,
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.askAiThinking,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmittedBanner extends StatelessWidget {
  const _SubmittedBanner({required this.reportId, required this.onOpen});
  final String reportId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Card(
      key: const Key('askAiSubmittedBanner'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.askAiSubmittedTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l.askAiSubmittedBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onOpen, child: Text(l.askAiOpen)),
          ],
        ),
      ),
    );
  }
}

class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.l10n.askAiBeta,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
