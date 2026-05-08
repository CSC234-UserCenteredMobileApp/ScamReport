import 'dart:convert';
import 'dart:typed_data';

import '../domain/entities/ai_draft.dart';
import 'attachment_picker.dart';

/// Persistable snapshot of the parts of `AskAiChatState` that should survive
/// an app kill. Pure-Dart so this is easy to round-trip in unit tests.
class AskAiPersistedState {
  AskAiPersistedState({
    this.conversationId,
    this.activeDraft,
    this.activeEvidence,
    this.stagedAttachments = const [],
    this.conversationAttachments = const [],
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  final String? conversationId;
  final AiDraft? activeDraft;
  final List<StagedAttachment>? activeEvidence;
  final List<StagedAttachment> stagedAttachments;
  final List<StagedAttachment> conversationAttachments;
  final DateTime savedAt;

  /// True when none of the persisted fields hold meaningful state. Caller
  /// can short-circuit the save to a delete in that case.
  bool get isEmpty =>
      conversationId == null &&
      activeDraft == null &&
      (activeEvidence == null || activeEvidence!.isEmpty) &&
      stagedAttachments.isEmpty &&
      conversationAttachments.isEmpty;
}

class AskAiStateCodec {
  static const int currentVersion = 1;

  static String encode(AskAiPersistedState state) {
    return jsonEncode({
      'v': currentVersion,
      'conversationId': state.conversationId,
      'activeDraft': state.activeDraft != null
          ? _draftToJson(state.activeDraft!)
          : null,
      'activeEvidence': state.activeEvidence
          ?.map(_attachmentToJson)
          .toList(growable: false),
      'stagedAttachments':
          state.stagedAttachments.map(_attachmentToJson).toList(growable: false),
      'conversationAttachments': state.conversationAttachments
          .map(_attachmentToJson)
          .toList(growable: false),
      'savedAt': state.savedAt.toIso8601String(),
    });
  }

  /// Returns null on parse failure, version mismatch, or any structural issue
  /// — the caller treats this as "no cached state" and clears the row.
  static AskAiPersistedState? decode(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final v = j['v'];
      if (v != currentVersion) return null;
      return AskAiPersistedState(
        conversationId: j['conversationId'] as String?,
        activeDraft: _draftFromJson(j['activeDraft'] as Map<String, dynamic>?),
        activeEvidence: _attachmentsFromJson(j['activeEvidence']),
        stagedAttachments:
            _attachmentsFromJson(j['stagedAttachments']) ?? const [],
        conversationAttachments:
            _attachmentsFromJson(j['conversationAttachments']) ?? const [],
        savedAt: DateTime.tryParse(j['savedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _draftToJson(AiDraft d) => {
        'title': d.title,
        'description': d.description,
        'scamTypeCode': d.scamTypeCode,
        'targetIdentifier': d.targetIdentifier,
        'targetIdentifierKind': d.targetIdentifierKind?.name,
      };

  static AiDraft? _draftFromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final kind = j['targetIdentifierKind'] as String?;
    return AiDraft(
      title: j['title'] as String,
      description: j['description'] as String,
      scamTypeCode: j['scamTypeCode'] as String,
      targetIdentifier: j['targetIdentifier'] as String?,
      targetIdentifierKind: switch (kind) {
        'phone' => TargetIdentifierKind.phone,
        'url' => TargetIdentifierKind.url,
        'other' => TargetIdentifierKind.other,
        _ => null,
      },
    );
  }

  static Map<String, dynamic> _attachmentToJson(StagedAttachment a) => {
        'bytesB64': base64Encode(a.bytes),
        'mimeType': a.mimeType,
        'filename': a.filename,
      };

  static List<StagedAttachment>? _attachmentsFromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is! List) return null;
    return raw
        .cast<Map<String, dynamic>>()
        .map((j) => StagedAttachment(
              bytes: Uint8List.fromList(base64Decode(j['bytesB64'] as String)),
              mimeType: j['mimeType'] as String,
              filename: j['filename'] as String,
            ))
        .toList(growable: false);
  }
}
