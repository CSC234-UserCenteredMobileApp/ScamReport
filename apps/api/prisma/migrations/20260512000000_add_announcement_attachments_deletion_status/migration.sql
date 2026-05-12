-- CreateEnum
CREATE TYPE "deletion_request_status" AS ENUM ('pending', 'approved', 'rejected');

-- AlterTable
ALTER TABLE "account_deletion_requests" ADD COLUMN     "rejection_reason" TEXT,
ADD COLUMN     "reviewed_at" TIMESTAMPTZ,
ADD COLUMN     "reviewed_by_admin_id" TEXT,
ADD COLUMN     "status" "deletion_request_status" NOT NULL DEFAULT 'pending';

-- CreateTable
CREATE TABLE "announcement_attachments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "announcement_id" UUID NOT NULL,
    "storage_path" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "mime_type" TEXT NOT NULL,
    "size_bytes" BIGINT NOT NULL,
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "announcement_attachments_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "announcement_attachments" ADD CONSTRAINT "announcement_attachments_announcement_id_fkey" FOREIGN KEY ("announcement_id") REFERENCES "announcements"("id") ON DELETE CASCADE ON UPDATE CASCADE;
