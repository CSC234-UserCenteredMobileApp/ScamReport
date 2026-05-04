import 'dart:convert';
import 'package:http/http.dart' as http;

class CallScreeningApiClient {
  const CallScreeningApiClient({required this.client, required this.baseUrl});

  final http.Client client;
  final String baseUrl;

  Future<List<String>> fetchScamPhones() async {
    final uri = Uri.parse('$baseUrl/check/phones');
    final res = await client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('fetchScamPhones failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<String>.from(body['phones'] as List);
  }
}
