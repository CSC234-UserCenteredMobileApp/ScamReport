import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/api_client.dart';
import '../domain/entities/ai_draft.dart';
import '../domain/failures.dart';

/// Mobile shape mirroring the server's `EvidenceMetadata` schema returned
/// by POST /reports/evidence. Stored alongside the bytes by the caller so
/// the same upload doesn't repeat on retry.
class EvidenceMetadata {
  EvidenceMetadata({
    required this.storagePath,
    required this.kind,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String storagePath;
  final String kind; // 'image' | 'pdf'
  final String mimeType;
  final int sizeBytes;

  Map<String, dynamic> toJson() => {
        'storagePath': storagePath,
        'kind': kind,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
      };
}

/// Thin wrapper around POST /reports for the "Submit drafted report" path.
/// Also exposes uploadEvidence so the editor's evidence list can be uploaded
/// before the create-report call.
class ReportsSubmitApi {
  ReportsSubmitApi(this._http, this._firebaseAuth);
  final http.Client _http;
  final FirebaseAuth _firebaseAuth;

  Future<String> _bearer() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw const AskAiUnauthorizedFailure();
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const AskAiUnauthorizedFailure();
    }
    return token;
  }

  /// Uploads one evidence file via multipart `POST /reports/evidence`.
  /// Returns the metadata to pass back inside the create-report body.
  Future<EvidenceMetadata> uploadEvidence({
    required Uint8List bytes,
    required String mimeType,
    required String filename,
  }) async {
    final token = await _bearer();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBaseUrl/reports/evidence'),
    );
    req.headers['Authorization'] = 'Bearer $token';
    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );
    final streamed = await _http.send(req);
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 401) throw const AskAiUnauthorizedFailure();
    if (res.statusCode == 413) {
      throw AskAiValidationFailure(_extractMessage(res));
    }
    if (res.statusCode == 415) {
      throw AskAiValidationFailure(_extractMessage(res));
    }
    if (res.statusCode != 200) {
      throw AskAiUnknownFailure(
        'HTTP ${res.statusCode}: ${_extractMessage(res)}',
      );
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return EvidenceMetadata(
      storagePath: body['storagePath'] as String,
      kind: body['kind'] as String,
      mimeType: body['mimeType'] as String,
      sizeBytes: (body['sizeBytes'] as num).toInt(),
    );
  }

  Future<({String reportId, DateTime createdAt})> submit({
    required AiDraft draft,
    required String sourceConversationId,
    String? clientSubmissionId,
    List<EvidenceMetadata> evidenceFiles = const [],
  }) async {
    final token = await _bearer();
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
        'evidenceFiles': evidenceFiles.map((e) => e.toJson()).toList(),
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
