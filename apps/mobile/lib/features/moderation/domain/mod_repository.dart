import 'mod_report.dart';

abstract class ModRepository {
  Future<ModQueueData> getQueue();
  Future<ModReportDetail> getDetail(String reportId);
  Future<void> approve(String reportId, String remark);
  Future<void> reject(String reportId, String remark);
  Future<void> flag(String reportId, String remark);
  Future<void> unflag(String reportId, String remark);
}
