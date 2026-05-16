import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n.dart';
import '../../data/attachment_picker.dart';
import '../../domain/entities/ai_draft.dart';
import '../../domain/failures.dart';
import '../ask_ai_providers.dart';
import 'attachment_chip.dart';

/// Result of editing a draft. The caller submits both the draft fields and
/// the curated evidence file list to POST /reports.
class DraftEditorResult {
  DraftEditorResult({required this.draft, required this.evidence});
  final AiDraft draft;
  final List<StagedAttachment> evidence;
}

class DraftEditorSheet extends ConsumerStatefulWidget {
  const DraftEditorSheet({
    super.key,
    required this.initial,
    this.initialEvidence = const [],
  });
  final AiDraft initial;
  final List<StagedAttachment> initialEvidence;

  static const _scamTypes = [
    'phone_impersonation',
    'phishing_sms',
    'fake_qr',
    'ecommerce_fraud',
    'investment_fraud',
    'romance_scam',
    'other',
  ];

  @override
  ConsumerState<DraftEditorSheet> createState() => _DraftEditorSheetState();
}

class _DraftEditorSheetState extends ConsumerState<DraftEditorSheet> {
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _identifier;
  late String _scamType;
  late TargetIdentifierKind? _kind;
  late List<StagedAttachment> _evidence;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial.title);
    _description = TextEditingController(text: widget.initial.description);
    _identifier =
        TextEditingController(text: widget.initial.targetIdentifier ?? '');
    _scamType = widget.initial.scamTypeCode;
    _kind = widget.initial.targetIdentifierKind;
    _evidence = [...widget.initialEvidence];
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _identifier.dispose();
    super.dispose();
  }

  void _save() {
    final trimmedId = _identifier.text.trim();
    final result = AiDraft(
      title: _title.text.trim(),
      description: _description.text.trim(),
      scamTypeCode: _scamType,
      targetIdentifier: trimmedId.isEmpty ? null : trimmedId,
      targetIdentifierKind: trimmedId.isEmpty ? null : _kind,
      // Preserve the AI's name inference through the manual edit path.
      suspectedScammerName: widget.initial.suspectedScammerName,
    );
    Navigator.of(context).pop(
      DraftEditorResult(draft: result, evidence: _evidence),
    );
  }

  Future<void> _addEvidence() async {
    final picker = ref.read(attachmentPickerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    if (_evidence.length >= maxAttachmentsPerMessage) {
      messenger.showSnackBar(SnackBar(content: Text(l.askAiEvidenceCapReached)));
      return;
    }
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
      if (picked != null) {
        setState(() => _evidence.add(picked));
      }
    } on AskAiFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _removeEvidence(int i) {
    setState(() => _evidence.removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final l = context.l10n;
    final atCap = _evidence.length >= maxAttachmentsPerMessage;
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.askAiDraftSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('askAiDraftTitle'),
                  controller: _title,
                  decoration:
                      InputDecoration(labelText: l.askAiDraftFieldTitle),
                  maxLength: 200,
                ),
                TextField(
                  key: const Key('askAiDraftDescription'),
                  controller: _description,
                  decoration: InputDecoration(
                      labelText: l.askAiDraftFieldDescription),
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('askAiDraftScamType'),
                  // ignore: deprecated_member_use
                  value: _scamType,
                  decoration:
                      InputDecoration(labelText: l.askAiDraftFieldScamType),
                  items: [
                    for (final code in DraftEditorSheet._scamTypes)
                      DropdownMenuItem(value: code, child: Text(code)),
                  ],
                  onChanged: (v) => setState(() => _scamType = v ?? _scamType),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('askAiDraftIdentifier'),
                  controller: _identifier,
                  decoration: InputDecoration(
                    labelText: l.askAiDraftFieldIdentifier,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TargetIdentifierKind?>(
                  key: const Key('askAiDraftIdentifierKind'),
                  // ignore: deprecated_member_use
                  value: _kind,
                  decoration:
                      InputDecoration(labelText: l.askAiDraftFieldKind),
                  items: [
                    DropdownMenuItem(
                        value: null, child: Text(l.askAiKindNone)),
                    DropdownMenuItem(
                        value: TargetIdentifierKind.phone,
                        child: Text(l.askAiKindPhone)),
                    DropdownMenuItem(
                        value: TargetIdentifierKind.url,
                        child: Text(l.askAiKindUrl)),
                    DropdownMenuItem(
                        value: TargetIdentifierKind.other,
                        child: Text(l.askAiKindOther)),
                  ],
                  onChanged: (v) => setState(() => _kind = v),
                ),
                const SizedBox(height: 16),
                _EvidenceSection(
                  evidence: _evidence,
                  onAdd: atCap ? null : _addEvidence,
                  onRemove: _removeEvidence,
                  countLabel: l.askAiEvidenceCount(_evidence.length),
                  title: l.askAiEvidenceTitle,
                  addLabel: l.askAiEvidenceAdd,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l.askAiCancel),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('askAiDraftSave'),
                      onPressed: _save,
                      child: Text(l.askAiSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({
    required this.evidence,
    required this.onAdd,
    required this.onRemove,
    required this.countLabel,
    required this.title,
    required this.addLabel,
  });

  final List<StagedAttachment> evidence;
  final VoidCallback? onAdd;
  final void Function(int) onRemove;
  final String countLabel;
  final String title;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Text(countLabel, style: theme.textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < evidence.length; i++)
              AttachmentChip(
                key: ValueKey(evidence[i].bytes),
                bytes: evidence[i].bytes,
                mimeType: evidence[i].mimeType,
                onRemove: () => onRemove(i),
              ),
            OutlinedButton.icon(
              key: const Key('askAiEvidenceAddButton'),
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: Text(addLabel),
            ),
          ],
        ),
      ],
    );
  }
}
