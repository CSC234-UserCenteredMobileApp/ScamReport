import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/api_client.dart';

class AnnouncementEditorApi {
  AnnouncementEditorApi(this._client, this._auth);

  final http.Client _client;
  final FirebaseAuth _auth;

  Future<Map<String, String>> _authHeaders() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in');
    final token = await user.getIdToken();
    if (token == null) throw StateError('Failed to get ID token');
    return {
      'Authorization': 'Bearer $token',
      'content-type': 'application/json',
    };
  }

  Future<List<dynamic>> fetchAll() async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/admin/announcements'),
      headers: await _authHeaders(),
    );
    _check(res, 'GET /admin/announcements');
    return (jsonDecode(res.body) as Map<String, dynamic>)['items']
        as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchDetail(String id) async {
    final res = await _client.get(
      Uri.parse('$apiBaseUrl/admin/announcements/$id'),
      headers: await _authHeaders(),
    );
    _check(res, 'GET /admin/announcements/$id');
    return (jsonDecode(res.body) as Map<String, dynamic>)['item']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postCreate(Map<String, dynamic> body) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/admin/announcements'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    _check(res, 'POST /admin/announcements');
    return (jsonDecode(res.body) as Map<String, dynamic>)['item']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putUpdate(
      String id, Map<String, dynamic> body) async {
    final res = await _client.put(
      Uri.parse('$apiBaseUrl/admin/announcements/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    _check(res, 'PUT /admin/announcements/$id');
    return (jsonDecode(res.body) as Map<String, dynamic>)['item']
        as Map<String, dynamic>;
  }

  Future<void> deleteAnnouncement(String id) async {
    final res = await _client.delete(
      Uri.parse('$apiBaseUrl/admin/announcements/$id'),
      headers: await _authHeaders(),
    );
    _check(res, 'DELETE /admin/announcements/$id');
  }

  Future<Map<String, dynamic>> postPublish(String id,
      {required bool pushToFcm}) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/admin/announcements/$id/publish'),
      headers: await _authHeaders(),
      body: jsonEncode({'pushToFcm': pushToFcm}),
    );
    _check(res, 'POST /admin/announcements/$id/publish');
    return (jsonDecode(res.body) as Map<String, dynamic>)['item']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postUnpublish(String id) async {
    final res = await _client.post(
      Uri.parse('$apiBaseUrl/admin/announcements/$id/unpublish'),
      headers: await _authHeaders(),
    );
    _check(res, 'POST /admin/announcements/$id/unpublish');
    // unpublish returns AdminAnnouncementActionResponse, not full detail
    // caller must refetch detail after this
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postAttachment(
      String announcementId, PlatformFile file) async {
    final headers = await _authHeaders();
    // Remove content-type from auth headers — multipart sets its own boundary
    headers.remove('content-type');

    final uri = Uri.parse(
        '$apiBaseUrl/admin/announcements/$announcementId/attachments');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
          contentType: MediaType.parse(file.extension != null
              ? _mimeFromExt(file.extension!)
              : 'application/octet-stream'),
        ),
      );
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _check(res, 'POST /admin/announcements/$announcementId/attachments');
    return (jsonDecode(res.body) as Map<String, dynamic>)['attachment']
        as Map<String, dynamic>;
  }

  Future<void> deleteAttachment(
      String announcementId, String attachmentId) async {
    final res = await _client.delete(
      Uri.parse(
          '$apiBaseUrl/admin/announcements/$announcementId/attachments/$attachmentId'),
      headers: await _authHeaders(),
    );
    _check(res,
        'DELETE /admin/announcements/$announcementId/attachments/$attachmentId');
  }

  String _mimeFromExt(String ext) => switch (ext.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'pdf' => 'application/pdf',
        _ => 'application/octet-stream',
      };

  void _check(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$label failed with ${res.statusCode}: ${res.body}');
    }
  }
}
