import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Override at launch time. Defaults work for iOS simulator and desktop.
//   Android emulator:        flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
//   Physical Android device: flutter run --dart-define=API_BASE_URL=http://<LAN-ip>:3000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});
