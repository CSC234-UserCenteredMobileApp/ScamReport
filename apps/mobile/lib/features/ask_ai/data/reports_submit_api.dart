import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/entities/ai_draft.dart';
import '../domain/failures.dart';

/// Thin wrapper around POST /reports for the "Submit drafted report" path.
/// Lives inside the ask_ai feature because it's the only consumer in this
/// release; when /submit-report ships its own screen it can extract this
/// into a shared `features/reports/data/` helper.
class ReportsSubmitApi {
  ReportsSubmitApi(this._http, this._firebaseAuth);
  final http.Client _http;
  final FirebaseAuth _firebaseAuth;

  Future<({String reportId, DateTime createdAt})> submit({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const AskAiUnauthorizedFailure();
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const AskAiUnauthorizedFailure();
    }

    final res = await _http.post(
      Uri.parse('$apiBaseUrl/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'title': draft.title,
        'description': draft.description,
        'scamTypeCode': draft.scamTypeCode,
        if (draft.targetIdentifier != null)
          'targetIdentifier': draft.targetIdentifier,
        if (draft.targetIdentifierKind != null)
          'targetIdentifierKind': draft.targetIdentifierKind!.name,
        'evidenceFiles': const [],
        'sourceConversationId': sourceConversationId,
        if (clientSubmissionId != null)
          'clientSubmissionId': clientSubmissionId,
      }),
    );

    if (res.statusCode == 401) throw const AskAiUnauthorizedFailure();
    if (res.statusCode == 422 || res.statusCode == 400) {
      throw AskAiValidationFailure(_extractMessage(res));
    }
    if (res.statusCode != 200) {
      throw AskAiUnknownFailure('HTTP ${res.statusCode}: ${_extractMessage(res)}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      reportId: body['id'] as String,
      createdAt: DateTime.parse(body['createdAt'] as String),
    );
  }

  String _extractMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = body['error'] ?? body['summary'] ?? body['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return res.reasonPhrase ?? 'Request failed';
  }
}
