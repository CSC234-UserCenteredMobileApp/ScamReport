import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/api_client.dart';
import '../domain/entities/ai_draft.dart';
import '../domain/entities/chat_attachment.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/similar_report.dart';
import '../domain/entities/turn_outcome.dart';
import '../domain/failures.dart';
import 'attachment_picker.dart';

/// Thin HTTP wrapper around the /ask-ai/* endpoints. Maps JSON shapes from
/// `packages/shared` into domain entities. Authentication is per-request:
/// we fetch the current Firebase ID token before each call so a refresh
/// happens inside firebase_auth and we always send a fresh JWT.
class AskAiApiClient {
  AskAiApiClient(this._http, this._firebaseAuth, {String Function()? locale})
      : _locale = locale ?? (() => 'th');

  final http.Client _http;
  final FirebaseAuth _firebaseAuth;
  // Returns 'th' or 'en' — read from SettingsState. Server forwards to
  // Gemini as a hard "RESPOND IN" rule. iter-5 language locking.
  final String Function() _locale;

  Future<Map<String, String>> _authHeaders() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AskAiUnauthorizedFailure();
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const AskAiUnauthorizedFailure();
    }
    return {
      'Authorization': 'Bearer $token',
      'content-type': 'application/json',
    };
  }

  Never _throwForStatus(http.Response response) {
    final code = response.statusCode;
    if (code == 401) throw const AskAiUnauthorizedFailure();
    if (code == 404) throw const AskAiNotFoundFailure();
    if (code == 429) throw const AskAiRateLimitedFailure();
    if (code == 422 || code == 400) {
      throw AskAiValidationFailure(_extractMessage(response));
    }
    throw AskAiUnknownFailure('HTTP $code: ${_extractMessage(response)}');
  }

  String _extractMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = body['error'] ?? body['summary'] ?? body['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {/* fall-through */}
    return response.reasonPhrase ?? 'Request failed';
  }

  Future<String> createConversation() async {
    final headers = await _authHeaders();
    final res = await _http.post(
      Uri.parse('$apiBaseUrl/ask-ai/conversations'),
      headers: headers,
      body: '{}',
    );
    if (res.statusCode != 200) _throwForStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['conversationId'] as String;
  }

  Future<List<ConversationSummary>> listConversations() async {
    final headers = await _authHeaders();
    final res = await _http.get(
      Uri.parse('$apiBaseUrl/ask-ai/conversations'),
      headers: headers,
    );
    if (res.statusCode != 200) _throwForStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (body['items'] as List).cast<Map<String, dynamic>>();
    return items
        .map(
          (j) => ConversationSummary(
            id: j['id'] as String,
            createdAt: DateTime.parse(j['createdAt'] as String),
            lastMessageAt: DateTime.parse(j['lastMessageAt'] as String),
            preview: j['preview'] as String? ?? '',
            linkedReportId: j['linkedReportId'] as String?,
          ),
        )
        .toList();
  }

  Future<ConversationDetail> getConversation(String id) async {
    final headers = await _authHeaders();
    final res = await _http.get(
      Uri.parse('$apiBaseUrl/ask-ai/conversations/$id'),
      headers: headers,
    );
    if (res.statusCode != 200) _throwForStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return _conversationFromJson(body);
  }

  Future<void> deleteConversation(String id) async {
    final headers = await _authHeaders();
    final res = await _http.delete(
      Uri.parse('$apiBaseUrl/ask-ai/conversations/$id'),
      headers: headers,
    );
    if (res.statusCode != 200) _throwForStatus(res);
  }

  Future<TurnOutcome> sendMessage(
    String conversationId,
    String content, {
    List<String> attachmentIds = const [],
  }) async {
    final headers = await _authHeaders();
    final res = await _http.post(
      Uri.parse('$apiBaseUrl/ask-ai/conversations/$conversationId/messages'),
      headers: headers,
      body: jsonEncode({
        'content': content,
        'attachmentIds': attachmentIds,
        'locale': _locale(),
      }),
    );
    if (res.statusCode != 200) _throwForStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return _turnFromJson(body);
  }

  Future<TurnOutcome> sendMessageMultipart(
    String conversationId,
    String content,
    List<StagedAttachment> attachments,
  ) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const AskAiUnauthorizedFailure();
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw const AskAiUnauthorizedFailure();

    final req = http.MultipartRequest(
      'POST',
      Uri.parse(
        '$apiBaseUrl/ask-ai/conversations/$conversationId/messages/multipart',
      ),
    );
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['content'] = content;
    req.fields['locale'] = _locale();
    for (var i = 0; i < attachments.length && i < 3; i++) {
      final a = attachments[i];
      req.files.add(
        http.MultipartFile.fromBytes(
          'file$i',
          Uint8List.fromList(a.bytes),
          filename: a.filename,
          contentType: MediaType.parse(a.mimeType),
        ),
      );
    }
    final streamed = await _http.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) _throwForStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return _turnFromJson(body);
  }

  // ---- json mappers ----

  ChatRole _roleFromString(String role) =>
      role == 'assistant' ? ChatRole.assistant : ChatRole.user;

  ChatAttachment _attachmentFromJson(Map<String, dynamic> j) {
    return ChatAttachment(
      id: j['id'] as String,
      mimeType: j['mimeType'] as String,
      sizeBytes: (j['sizeBytes'] as num).toInt(),
      signedUrl: j['signedUrl'] as String?,
    );
  }

  ChatMessage _messageFromJson(Map<String, dynamic> j) {
    final atts = (j['attachments'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_attachmentFromJson)
        .toList();
    return ChatMessage(
      id: j['id'] as String,
      role: _roleFromString(j['role'] as String),
      content: j['content'] as String,
      intentDetected: (j['intentDetected'] as bool?) ?? false,
      createdAt: DateTime.parse(j['createdAt'] as String),
      attachments: atts,
    );
  }

  ConversationDetail _conversationFromJson(Map<String, dynamic> j) {
    final messages = (j['messages'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_messageFromJson)
        .toList();
    final draftJson = j['draft'];
    PersistedDraft? draft;
    if (draftJson is Map<String, dynamic>) {
      final ids = (draftJson['evidenceAttachmentIds'] as List? ?? const [])
          .cast<String>();
      draft = PersistedDraft(
        draft: AiDraft(
          title: draftJson['title'] as String,
          description: draftJson['description'] as String,
          scamTypeCode: draftJson['scamTypeCode'] as String,
          targetIdentifier: draftJson['targetIdentifier'] as String?,
          targetIdentifierKind:
              switch (draftJson['targetIdentifierKind'] as String?) {
            'phone' => TargetIdentifierKind.phone,
            'url' => TargetIdentifierKind.url,
            'other' => TargetIdentifierKind.other,
            _ => null,
          },
        ),
        userEditedDraft: (draftJson['userEditedDraft'] as bool?) ?? false,
        evidenceAttachmentIds: ids,
      );
    }
    final evidenceAttachments = (j['evidenceAttachments'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_attachmentFromJson)
        .toList();
    return ConversationDetail(
      id: j['id'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      messages: messages,
      linkedReportId: j['linkedReportId'] as String?,
      draft: draft,
      evidenceAttachments: evidenceAttachments,
    );
  }

  /// PATCH /ask-ai/conversations/:id/draft — persists the active draft
  /// server-side so it syncs across devices and survives app kill. Pass
  /// `null` to clear the server draft. iter-5 cross-device sync.
  Future<void> upsertDraft(
    String conversationId,
    PersistedDraft? payload,
  ) async {
    final headers = await _authHeaders();
    final body = payload == null
        ? 'null'
        : jsonEncode({
            'title': payload.draft.title,
            'description': payload.draft.description,
            'scamTypeCode': payload.draft.scamTypeCode,
            'targetIdentifier': payload.draft.targetIdentifier,
            'targetIdentifierKind': payload.draft.targetIdentifierKind?.name,
            'userEditedDraft': payload.userEditedDraft,
            'evidenceAttachmentIds': payload.evidenceAttachmentIds,
          });
    final res = await _http.patch(
      Uri.parse('$apiBaseUrl/ask-ai/conversations/$conversationId/draft'),
      headers: headers,
      body: body,
    );
    if (res.statusCode != 200) _throwForStatus(res);
  }

  AiDraft? _draftFromJson(Map<String, dynamic>? j) {
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

  TurnOutcome _turnFromJson(Map<String, dynamic> j) {
    return TurnOutcome(
      userMessage: _messageFromJson(j['userMessage'] as Map<String, dynamic>),
      assistantMessage:
          _messageFromJson(j['assistantMessage'] as Map<String, dynamic>),
      intentDetected: (j['intentDetected'] as bool?) ?? false,
      reportable: (j['reportable'] as bool?) ?? false,
      hasEnoughInfo: (j['hasEnoughInfo'] as bool?) ?? false,
      similarReports: ((j['similarReports'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(SimilarReport.fromJson)
          .toList(growable: false),
      draft: _draftFromJson(j['draft'] as Map<String, dynamic>?),
      // Default to empty list when older servers don't include the field —
      // mobile's fallback is "no question pending".
      missingFacts:
          (j['missingFacts'] as List? ?? const []).cast<String>(),
    );
  }
}
