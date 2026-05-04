import 'check_result.dart';

abstract class CheckRepository {
  Future<CheckResult> runCheck(CheckQuery query);
}
