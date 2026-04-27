import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Override at launch time. Defaults work for iOS simulator and desktop.
//   Android emulator:        10.0.2.2 (automatically detected)
//   Physical Android device: flutter run --dart-define=API_BASE_URL=http://<LAN-ip>:3000
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
