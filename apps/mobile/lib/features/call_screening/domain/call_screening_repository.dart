import 'blocked_call.dart';

abstract class CallScreeningRepository {
  Future<void> syncPhoneList();
  Future<List<BlockedCall>> getBlockedCalls();
  Future<void> setEnabled(bool enabled);
  Future<bool> isEnabled();
}
