import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/entities/ai_draft.dart';

class DraftEditorSheet extends StatefulWidget {
  const DraftEditorSheet({super.key, required this.initial});
  final AiDraft initial;

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
  State<DraftEditorSheet> createState() => _DraftEditorSheetState();
}

class _DraftEditorSheetState extends State<DraftEditorSheet> {
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _identifier;
  late String _scamType;
  late TargetIdentifierKind? _kind;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial.title);
    _description = TextEditingController(text: widget.initial.description);
    _identifier = TextEditingController(text: widget.initial.targetIdentifier ?? '');
    _scamType = widget.initial.scamTypeCode;
    _kind = widget.initial.targetIdentifierKind;
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
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final l = context.l10n;
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
                  decoration: InputDecoration(labelText: l.askAiDraftFieldTitle),
                  maxLength: 200,
                ),
                TextField(
                  key: const Key('askAiDraftDescription'),
                  controller: _description,
                  decoration:
                      InputDecoration(labelText: l.askAiDraftFieldDescription),
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('askAiDraftScamType'),
                  initialValue: _scamType,
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
                  initialValue: _kind,
                  decoration:
                      InputDecoration(labelText: l.askAiDraftFieldKind),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l.askAiKindNone)),
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
