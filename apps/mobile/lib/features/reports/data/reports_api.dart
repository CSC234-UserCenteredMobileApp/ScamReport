import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/api_client.dart';
import '../domain/my_report.dart';

class ReportsApi {
  ReportsApi(this._client, this._firebaseAuth);

  final http.Client _client;
  final FirebaseAuth _firebaseAuth;

  Future<String?> _bearerToken() async {
    return _firebaseAuth.currentUser?.getIdToken();
  }

  Future<Map<String, dynamic>> fetchReportDetail(String id) async {
    final uri = Uri.parse('$apiBaseUrl/reports/$id');
    final response = await _client.get(
      uri,
      headers: {'content-type': 'application/json'},
    );
    if (response.statusCode == 404) {
      throw const ReportNotFoundException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET /reports/$id failed with ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchMyReportDetail(String id) async {
    final token = await _bearerToken();
    if (token == null) throw const ReportUnauthorizedException();

    final response = await _client.get(
      Uri.parse('$apiBaseUrl/reports/mine/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
    );
    if (response.statusCode == 401) throw const ReportUnauthorizedException();
    if (response.statusCode == 404) throw const ReportNotFoundException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET /reports/mine/$id failed with ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<MyReport>> fetchMyReports() async {
    final token = await _bearerToken();
    if (token == null) throw const ReportUnauthorizedException();

    final response = await _client.get(
      Uri.parse('$apiBaseUrl/reports/mine'),
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
    );
    if (response.statusCode == 401) throw const ReportUnauthorizedException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'GET /reports/mine failed with ${response.statusCode}: ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>;
    return items
        .map((e) => MyReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({String reportId, DateTime createdAt})> submitReport({
    required String title,
    required String description,
    required String scamTypeCode,
    String? targetIdentifier,
    String? targetIdentifierKind,
    List<Map<String, dynamic>> evidenceFiles = const [],
    String? clientSubmissionId,
  }) async {
    final token = await _bearerToken();
    if (token == null) throw const ReportUnauthorizedException();

    final response = await _client.post(
      Uri.parse('$apiBaseUrl/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'scamTypeCode': scamTypeCode,
        if (targetIdentifier != null && targetIdentifier.isNotEmpty)
          'targetIdentifier': targetIdentifier,
        if (targetIdentifierKind != null)
          'targetIdentifierKind': targetIdentifierKind,
        'evidenceFiles': evidenceFiles,
        if (clientSubmissionId != null) 'clientSubmissionId': clientSubmissionId,
      }),
    );

    if (response.statusCode == 401) throw const ReportUnauthorizedException();
    if (response.statusCode == 400) {
      throw ReportValidationException(_extractError(response));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'POST /reports failed with ${response.statusCode}: ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      reportId: body['id'] as String,
      createdAt: DateTime.parse(body['createdAt'] as String),
    );
  }

  Future<void> updateReport({
    required String reportId,
    required String title,
    required String description,
    required String scamTypeCode,
    String? targetIdentifier,
    String? targetIdentifierKind,
    List<Map<String, dynamic>> evidenceFiles = const [],
  }) async {
    final token = await _bearerToken();
    if (token == null) throw const ReportUnauthorizedException();

    final response = await _client.patch(
      Uri.parse('$apiBaseUrl/reports/$reportId'),
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'scamTypeCode': scamTypeCode,
        if (targetIdentifier != null && targetIdentifier.isNotEmpty)
          'targetIdentifier': targetIdentifier,
        if (targetIdentifierKind != null)
          'targetIdentifierKind': targetIdentifierKind,
        'evidenceFiles': evidenceFiles,
      }),
    );

    if (response.statusCode == 401) throw const ReportUnauthorizedException();
    if (response.statusCode == 400 || response.statusCode == 409) {
      throw ReportValidationException(_extractError(response));
    }
    if (response.statusCode == 404) throw const ReportNotFoundException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'PATCH /reports/$reportId failed with ${response.statusCode}: ${response.body}',
      );
    }
  }

  Future<void> withdrawReport(String reportId) async {
    final token = await _bearerToken();
    if (token == null) throw const ReportUnauthorizedException();

    final response = await _client.delete(
      Uri.parse('$apiBaseUrl/reports/$reportId'),
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
    );

    if (response.statusCode == 401) throw const ReportUnauthorizedException();
    if (response.statusCode == 409) {
      throw ReportValidationException(_extractError(response));
    }
    if (response.statusCode == 404) throw const ReportNotFoundException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'DELETE /reports/$reportId failed with ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Uploads one evidence file. Returns metadata to pass in evidenceFiles array.
  Future<Map<String, dynamic>> uploadEvidence({
    required Uint8List bytes,
    required String mimeType,
    required String filename,
  }) async {
    final token = await _bearerToken();
    if (token == null) throw const ReportUnauthorizedException();

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
    final streamed = await _client.send(req);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401) throw const ReportUnauthorizedException();
    if (response.statusCode == 413 || response.statusCode == 415) {
      throw ReportValidationException(_extractError(response));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'POST /reports/evidence failed with ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _extractError(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final msg = body['error'] ?? body['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return res.reasonPhrase ?? 'Request failed';
  }
}

class ReportNotFoundException implements Exception {
  const ReportNotFoundException();
}

class ReportUnauthorizedException implements Exception {
  const ReportUnauthorizedException();
}

class ReportValidationException implements Exception {
  const ReportValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}
