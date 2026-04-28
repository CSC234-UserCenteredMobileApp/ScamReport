# admin-review — Approve / Reject / Flag a report

**PRD:** FR-7.3–FR-7.6 / A-02  **Roles:** admin
**Flutter:** `apps/mobile/lib/features/moderation/presentation/admin_review_screen.dart` (planned)

**Snapshot:** `../snapshots/admin/admin-review.txt` · **Screenshot:** `../screenshots/admin/admin-review.png`

## Purpose

Admin reviews a single submitted report. Pick Approve / Reject / Flag for Discussion. Each requires a remark (FR-7.6). All actions append to the audit log.

## Layout (top-down)

- Top bar: back arrow + title `Review report`.
- **Status meta**: `Pending • <age>` (muted `bodySmall`).
- **Type chip + Title**.
- **Submitted by row**: masked handle + date (`Submitted by User_xxxx • <yyyy-mm-dd>`).
- **`DESCRIPTION`** uppercase label + paragraph body.
- **`TARGET IDENTIFIER`** uppercase label + identifier chip.
- **`EVIDENCE`** uppercase label + `EvidenceList` (count in parens).
- **`AUDIT TRAIL`** uppercase label + `AuditTrailRow` list:
  - First row always `Submitted` + the submission date.
  - Subsequent rows added by approve/reject/flag actions.
- **Action bar** at bottom (sticky above the bottom nav):
  - 3 buttons in a row: `Reject` (red outlined) / `Flag` (amber outlined) / `Approve` (primary filled).
- **`BottomNav`** (admin variant).

## States

- **Pending review** — 3 actions enabled.
- **Action chosen → remark dialog** — modal: textarea labelled `Remark` (required), `Cancel` / `Confirm <action>`. Submitting commits the audit entry.
- **Already-actioned (revisit)** — actions disabled, audit trail shows the prior decision. Useful when an admin opens a report from `mod` history.
- **Loading / Error** — standard.

## Interactions

- `Approve` → remark dialog → `POST /admin/reports/:id/approve` with remark. On success: toast `Approved.`, push `mod`, FCM push to reporter.
- `Reject` → same flow with `/reject`. Toast `Rejected.`.
- `Flag` → same with `/flag`. Stays in queue with team-note row visible on `mod`.
- Evidence row tap → preview overlay.
- Back → `mod`.

## Role variants

Admin-only. Same gating as `mod`.

## Notes

- Per FR-7.6, every action commits `admin_id + timestamp + remark`. Do not allow remark to be empty — enforce at form-level validation.
- The "Submitted by" line shows `User_xxxx`; do not show the real account/email even to admins, unless the team explicitly approves a separate moderator-only view.
