# deletion-requests — Review account-deletion requests

**PRD:** FR-10.2 + FR-7 audit trail / A-04  **Roles:** admin
**Web:** `apps/web/src/features/deletion-requests/pages/deletion-page.tsx`

## Purpose

Admin reviews user-initiated account-deletion requests. Approve kicks off the 7-day soft-delete + purge window. Reject sends an FCM notification carrying the rejection reason and keeps the account active.

## Layout (top-down)

- `PageHeader`: title `Deletion requests`, subtitle `Review and act on account-deletion requests from users.`
- **Stats strip**: single card `Pending` with the live `pendingCount` returned by the list endpoint. (No other counters in v1 — admin focus is the queue.)
- **Status filter chips**: `Pending` (default) / `Approved` / `Rejected`. Drives the `?status=` query param. Active chip uses the `primary` token.
- **Table** (TanStack Table on shadcn `table.tsx`):
  - `Handle` — masked `User_xxxxxxxx` only. **Never** show real id, email, or firebase uid.
  - `Requested` — relative time (`formatDistanceToNowStrict`).
  - `Purge due` — formatted date.
  - `Status` — `StatusBadge` (`pending` / `approved` / `rejected`).
  - `Actions` — only on pending rows: `Approve` (destructive variant) + `Reject` (outline).
- **Empty state** — `Inbox` icon + `No deletion requests in this view.`

## Interactions

- `Approve` → `<ApproveConfirmDialog>` (destructive copy: *"This deletes the account and purges data after 7 days. Continue?"*) → `POST /admin/deletion-requests/:id/approve`. On success: optimistic remove from the active view + decrement `pendingCount`; toast `Request approved.`.
- `Reject` → `<RejectDialog>` with required `reason` textarea (1–500 chars, zod-resolved rhf) → `POST /admin/deletion-requests/:id/reject` with `{ reason }`. On success: optimistic remove + toast `Request rejected. User notified.`. The reason is forwarded to the user via FCM by the server.
- Status chip change → refetches the list under the new key.
- 409 (`already reviewed`) → toast `This request was already reviewed.` + invalidate list (someone else got there first).

## States

- **Pending tab default** — most common admin work.
- **Loading** — skeleton on the table + stats card.
- **Error** — `Alert` with `Try again` action that calls `refetch()`.
- **Optimistic remove + rollback** — `useApprove` / `useReject` snapshot the previous list under each filter key, replace optimistically, and restore on `onError`.

## Anonymity (PRD FR-7.4 / FR-7.8 parity)

- Server returns `userHandle` only (`User_xxxxxxxx` from a stable hash of the internal user id). Real id, email, firebase uid, and display name are excluded from the admin payload.
- Admin web never renders any field that could deanonymize the requester. A negative regex assertion is part of the page test.

## Role variants

Admin-only. Reached only inside `<ProtectedRoute role="admin">`.

## Mobile parity

None. Account-deletion review is a desktop-only workflow for v1. The user-facing deletion request lives on the mobile settings screen.

## Notes

- Approval is **irreversible** — the dialog uses the destructive button variant + plain-language copy. If the spec later requires the admin to type `DELETE` to confirm, we add that gate without changing the API.
- The 7-day purge window is server-controlled. No admin override surface in v1; that lives behind a follow-up "Purge now" button if ops demand it.
- i18n: keys live under the `announcements` namespace (`deletionRequests.*`) for v1 to avoid a new namespace bundle entry. Split into a dedicated `deletion-requests.json` if the string count grows past ~30.
