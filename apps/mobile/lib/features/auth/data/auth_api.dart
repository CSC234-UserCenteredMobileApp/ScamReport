import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/auth_user.dart';

class AuthApi {
  AuthApi(this._client, this._firebaseAuth);

  final http.Client _client;
  final FirebaseAuth _firebaseAuth;

  // POST /auth/sync — verifies the current Firebase ID token and upserts the
  // backend users row. Returns the synced AuthUser including our internal id.
  Future<AuthUser> sync() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw StateError('Cannot sync: no Firebase user is signed in.');
    }
    final token = await firebaseUser.getIdToken();
    if (token == null) {
      throw StateError('Failed to obtain Firebase ID token.');
    }

    final response = await _client.post(
      Uri.parse('$apiBaseUrl/auth/sync'),
      headers: {
        'Authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(
        'POST /auth/sync failed with ${response.statusCode}: ${response.body}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthUser.fromJson(body['user'] as Map<String, dynamic>);
  }
}
