import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/core/api_client.dart';
import 'package:mobile/features/example/presentation/example_screen.dart';

void main() {
  testWidgets('ExampleScreen renders items fetched from the API',
      (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/examples') {
        return http.Response(
          jsonEncode({
            'items': [
              {'id': '1', 'name': 'Foo'},
              {'id': '2', 'name': 'Bar'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not found', 404);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          httpClientProvider.overrideWithValue(mockClient),
        ],
        child: const MaterialApp(home: ExampleScreen()),
      ),
    );

    // Resolve the FutureProvider.
    await tester.pumpAndSettle();

    expect(find.text('Foo'), findsOneWidget);
    expect(find.text('Bar'), findsOneWidget);
  });
}
