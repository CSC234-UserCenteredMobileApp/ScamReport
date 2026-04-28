# announcement-editor — Create / edit announcements

**PRD:** FR-7.7 / A-03  **Roles:** admin
**Flutter:** `apps/mobile/lib/features/moderation/presentation/announcement_editor_screen.dart` (planned)

**Snapshot:** `../snapshots/admin/announcement-editor.txt` · **Screenshot:** `../screenshots/admin/announcement-editor.png`

## Purpose

Admin composes a new announcement or edits an existing draft. Optionally publishes and sends as an FCM push to all subscribed users (FR-8.4).

## Layout

- Top bar: back arrow + title `New announcement` (when `id` is null) or `Edit announcement` (when editing).
- **Category** field — segmented chip group with 3 options:
  - `Fraud Alert` (red tone)
  - `Tips` (green tone)
  - `Platform Update` (primary coral tone)
- **Title** field — single-line `TextField`.
- **Body** field — multi-line `TextField` with markdown-lite support (paragraphs + `• ` bullets — same conventions as `announcement-detail`).
- **Push toggle**:
  - Heading `Send as push notification`
  - Sub-label: `To all subscribed users (~<count>)` (muted)
  - Right side: `Switch`
- Action bar (sticky above bottom nav):
  - `Save draft` (text button) — left
  - `Publish` (primary `FilledButton`) — right
- **`BottomNav`** (admin variant).

## States

- **New** — title bar `New announcement`, all fields blank.
- **Editing draft** — `Edit announcement` title, fields populated, `Save draft` and `Publish` available.
- **Published** — already-live announcements open in a similar editor but `Publish` is replaced with `Unpublish` (FR-7.7).
- **Validation** — `Publish` disabled until title + body + category are set.
- **Submitting** — buttons disabled + spinner.
- **Push toggle ON + Publish** → confirm dialog `Send push to ~<count> users?` before commit.

## Interactions

- `Save draft` → `POST/PATCH /admin/announcements` (status=draft). Toast `Draft saved.` Stay on editor.
- `Publish` → `POST/PATCH /admin/announcements` (status=published). On success: toast `Published.`, push to `alerts`. If push toggle was on, fire FCM after the DB write.

## Role variants

Admin-only.

## Notes

- The push count `~1,840` in the prototype is hard-coded; pull live from `/admin/notifications/subscribers/count`.
- Title length cap should mirror the API; show a `0/N characters` counter like `submit-report` does.
- Markdown rendering on `announcement-detail` must match what the editor produces — pick a single Markdown subset (paragraphs + `• ` bullets) and document it inline near both screens.
