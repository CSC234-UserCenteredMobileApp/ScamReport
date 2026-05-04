import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Set API_BASE_URL via --dart-define-from-file=config.json (or --dart-define).
// config.json (gitignored): { "API_BASE_URL": "https://your-api.example.com" }
// See config.example.json for the template.
//
// Fallback defaults (no config file):
//   Android emulator  → 10.0.2.2:3000
//   iOS simulator / desktop → localhost:3000
String get apiBaseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;

  // In Android emulators, localhost refers to the emulator itself.
  // 10.0.2.2 is the special alias to the host computer's loopback.
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});
