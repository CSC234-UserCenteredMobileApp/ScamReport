import 'package:flutter/material.dart';

import '../../domain/entities/ai_draft.dart';

/// Inline consent gate that appears under the latest AI bubble when the AI
/// produced a reportable draft. FR-5.3 — the user must explicitly confirm
/// the report content (not their identity) will be public if approved.
class ConsentCard extends StatefulWidget {
  const ConsentCard({
    super.key,
    required this.draft,
    required this.onEdit,
    required this.onAskRedraft,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  final AiDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onAskRedraft;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  State<ConsentCard> createState() => _ConsentCardState();
}

class _ConsentCardState extends State<ConsentCard> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = _accepted && !widget.isSubmitting;
    return Card(
      key: const Key('askAiConsentCard'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit this report?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _DraftPreview(draft: widget.draft),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  key: const Key('askAiConsentEdit'),
                  onPressed: widget.isSubmitting ? null : widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit draft'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  key: const Key('askAiConsentRedraft'),
                  onPressed: widget.isSubmitting ? null : widget.onAskRedraft,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Ask AI to redraft'),
                ),
              ],
            ),
            const Divider(height: 24),
            CheckboxListTile(
              key: const Key('askAiConsentCheckbox'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _accepted,
              onChanged: widget.isSubmitting
                  ? null
                  : (v) => setState(() => _accepted = v ?? false),
              title: const Text(
                'I understand and agree.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'By submitting, you agree that this report — but never your identity — may be published to the verified feed once approved.',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('askAiConsentSubmit'),
                onPressed: canSubmit ? widget.onSubmit : null,
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(widget.isSubmitting ? 'Submitting…' : 'Submit report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftPreview extends StatelessWidget {
  const _DraftPreview({required this.draft});
  final AiDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(draft.title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Type: ${draft.scamTypeCode}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (draft.targetIdentifier != null) ...[
            const SizedBox(height: 4),
            Text(
              'Target: ${draft.targetIdentifier}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 8),
          Text(draft.description, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
