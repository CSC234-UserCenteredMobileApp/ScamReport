import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/example_item.dart';

class ExampleApi {
  ExampleApi(this._client);

  final http.Client _client;

  Future<List<ExampleItem>> fetchAll() async {
    final response = await _client.get(Uri.parse('$apiBaseUrl/examples'));
    if (response.statusCode != 200) {
      throw Exception('GET /examples failed with ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>;
    return items
        .map((e) => ExampleItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
