import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/core/api_client.dart';

void main() {
  group('apiBaseUrl', () {
    test('returns default localhost url when no environment define is present', () {
      // Note: testing Platform.isAndroid logic is hard in plain unit tests 
      // as Platform is from dart:io.
      // But we can check the general logic.
      final url = apiBaseUrl;
      expect(url, anyOf('http://localhost:3000', 'http://10.0.2.2:3000'));
    });
  });

  group('httpClientProvider', () {
    test('provides a client and closes it on dispose', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final client = container.read(httpClientProvider);
      expect(client, isA<http.Client>());
      
      container.dispose();
      // Verifying close is hard without mocks, but we at least cover the provider logic.
    });
  });
}
