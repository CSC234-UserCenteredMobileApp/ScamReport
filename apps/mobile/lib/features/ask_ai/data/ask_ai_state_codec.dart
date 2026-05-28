import 'dart:convert';
import 'dart:typed_data';

import 'attachment_picker.dart';

/// Persistable snapshot of composer state that should survive an app kill.
///
/// iter-5: drafts + curated evidence now live SERVER-SIDE (PATCHed via
/// `/ask-ai/conversations/:id/draft`). Drift only tracks the in-flight
/// composer state (current conversation + unsent stagedAttachments +
/// `conversationAttachments` cumulative cache for the editor's pre-fill
/// UX). Pure-Dart so this is easy to round-trip in unit tests.
class AskAiPersistedState {
  AskAiPersistedState({
    this.conversationId,
    this.userId,
    this.stagedAttachments = const [],
    this.conversationAttachments = const [],
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  final String? conversationId;
  // Firebase UID (iter-5 hardening). Drift row keyed by uid in payload so a
  // sign-out → sign-in-as-different-user doesn't leak the prior user's chat
  // into the new session.
  final String? userId;
  final List<StagedAttachment> stagedAttachments;
  final List<StagedAttachment> conversationAttachments;
  final DateTime savedAt;

  /// True when none of the persisted fields hold meaningful state. Caller
  /// can short-circuit the save to a delete in that case.
  bool get isEmpty =>
      conversationId == null &&
      stagedAttachments.isEmpty &&
      conversationAttachments.isEmpty;
}

class AskAiStateCodec {
  // Bumped from 1 → 2 in iter-5 (draft + evidence fields removed; userId
  // added). v=1 payloads decode → version mismatch → row dropped cleanly
  // by the caller.
  static const int currentVersion = 2;

  static String encode(AskAiPersistedState state) {
    return jsonEncode({
      'v': currentVersion,
      'conversationId': state.conversationId,
      'userId': state.userId,
      'stagedAttachments': state.stagedAttachments
          .map(_attachmentToJson)
          .toList(growable: false),
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
        userId: j['userId'] as String?,
        stagedAttachments:
            _attachmentsFromJson(j['stagedAttachments']) ?? const [],
        conversationAttachments:
            _attachmentsFromJson(j['conversationAttachments']) ?? const [],
        savedAt:
            DateTime.tryParse(j['savedAt'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
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
