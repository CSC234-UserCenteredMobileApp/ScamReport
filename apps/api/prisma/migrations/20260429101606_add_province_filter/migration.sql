-- DropForeignKey
ALTER TABLE "account_deletion_requests" DROP CONSTRAINT "account_deletion_requests_user_id_fkey";

-- DropForeignKey
ALTER TABLE "announcements" DROP CONSTRAINT "announcements_author_id_fkey";

-- DropForeignKey
ALTER TABLE "check_logs" DROP CONSTRAINT "check_logs_user_id_fkey";

-- DropForeignKey
ALTER TABLE "consent_records" DROP CONSTRAINT "consent_records_user_id_fkey";

-- DropForeignKey
ALTER TABLE "evidence_files" DROP CONSTRAINT "evidence_files_report_id_fkey";

-- DropForeignKey
ALTER TABLE "fcm_devices" DROP CONSTRAINT "fcm_devices_user_id_fkey";

-- DropForeignKey
ALTER TABLE "moderation_actions" DROP CONSTRAINT "moderation_actions_admin_id_fkey";

-- DropForeignKey
ALTER TABLE "moderation_actions" DROP CONSTRAINT "moderation_actions_report_id_fkey";

-- DropForeignKey
ALTER TABLE "report_embeddings" DROP CONSTRAINT "report_embeddings_report_id_fkey";

-- DropForeignKey
ALTER TABLE "reports" DROP CONSTRAINT "reports_reporter_id_fkey";

-- DropForeignKey
ALTER TABLE "reports" DROP CONSTRAINT "reports_scam_type_id_fkey";

-- DropForeignKey
ALTER TABLE "search_queries" DROP CONSTRAINT "search_queries_top_result_id_fkey";

-- DropForeignKey
ALTER TABLE "search_queries" DROP CONSTRAINT "search_queries_user_id_fkey";

-- DropIndex
DROP INDEX "report_embeddings_ivfflat_idx";

-- AlterTable
ALTER TABLE "announcements" ADD COLUMN     "province" TEXT;

-- AlterTable
ALTER TABLE "reports" ADD COLUMN     "province" TEXT;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "province" TEXT;

-- AddForeignKey
ALTER TABLE "consent_records" ADD CONSTRAINT "consent_records_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_reporter_id_fkey" FOREIGN KEY ("reporter_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reports" ADD CONSTRAINT "reports_scam_type_id_fkey" FOREIGN KEY ("scam_type_id") REFERENCES "scam_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "evidence_files" ADD CONSTRAINT "evidence_files_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moderation_actions" ADD CONSTRAINT "moderation_actions_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "moderation_actions" ADD CONSTRAINT "moderation_actions_admin_id_fkey" FOREIGN KEY ("admin_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "report_embeddings" ADD CONSTRAINT "report_embeddings_report_id_fkey" FOREIGN KEY ("report_id") REFERENCES "reports"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "announcements" ADD CONSTRAINT "announcements_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fcm_devices" ADD CONSTRAINT "fcm_devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "check_logs" ADD CONSTRAINT "check_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "search_queries" ADD CONSTRAINT "search_queries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "search_queries" ADD CONSTRAINT "search_queries_top_result_id_fkey" FOREIGN KEY ("top_result_id") REFERENCES "reports"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_deletion_requests" ADD CONSTRAINT "account_deletion_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- RenameIndex
ALTER INDEX "check_logs_input_idx" RENAME TO "check_logs_input_normalized_created_at_idx";

-- RenameIndex
ALTER INDEX "fcm_devices_user_idx" RENAME TO "fcm_devices_user_id_idx";

-- RenameIndex
ALTER INDEX "moderation_actions_report_idx" RENAME TO "moderation_actions_report_id_created_at_idx";

-- RenameIndex
ALTER INDEX "reports_reporter_created_idx" RENAME TO "reports_reporter_id_created_at_idx";

-- RenameIndex
ALTER INDEX "reports_scam_type_idx" RENAME TO "reports_scam_type_id_idx";

-- RenameIndex
ALTER INDEX "reports_status_created_idx" RENAME TO "reports_status_created_at_idx";
