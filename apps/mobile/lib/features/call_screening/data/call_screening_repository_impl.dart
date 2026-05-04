import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/blocked_call.dart';
import '../domain/call_screening_repository.dart';
import 'call_screening_api_client.dart';

const _keyPhones = 'scam_phones';
const _keyEnabled = 'call_screening_enabled';
const _keyBlocked = 'blocked_calls';

class CallScreeningRepositoryImpl implements CallScreeningRepository {
  const CallScreeningRepositoryImpl({
    required this.apiClient,
    required this.prefs,
  });

  final CallScreeningApiClient apiClient;
  final SharedPreferences prefs;

  @override
  Future<void> syncPhoneList() async {
    final phones = await apiClient.fetchScamPhones();
    await prefs.setString(_keyPhones, jsonEncode(phones));
  }

  @override
  Future<List<BlockedCall>> getBlockedCalls() async {
    final raw = prefs.getString(_keyBlocked) ?? '[]';
    final list = jsonDecode(raw) as List;
    return list
        .map(
          (e) => BlockedCall(
            number: e['number'] as String,
            blockedAt: DateTime.fromMillisecondsSinceEpoch(
              e['blockedAt'] as int,
            ),
          ),
        )
        .toList()
      ..sort((a, b) => b.blockedAt.compareTo(a.blockedAt));
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    await prefs.setBool(_keyEnabled, enabled);
  }

  @override
  Future<bool> isEnabled() async {
    return prefs.getBool(_keyEnabled) ?? false;
  }
}
