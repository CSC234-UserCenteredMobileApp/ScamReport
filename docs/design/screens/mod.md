# mod — Moderation queue

**PRD:** FR-7.1, FR-7.2 / A-01  **Roles:** admin
**Flutter:** `apps/mobile/lib/features/moderation/presentation/mod_screen.dart` (planned)

**Snapshot:** `../snapshots/admin/mod.txt` · **Screenshot:** `../screenshots/admin/mod.png`

## Purpose

Admin-only queue of pending and flagged reports, sorted by age. Flagged reports stay highlighted.

## Layout (top-down)

- Top bar: title `Moderation queue`.
- **Stats row** (3-up like `feed`'s `StatCardRow`):
  - `5 / PENDING`
  - `1 / FLAGGED`
  - `12h / AVG AGE`
- **Sort/filter row**: dropdown `Oldest first` (default) + chip `Priority flag` (toggle to surface only flagged rows).
- **Queue list** of `ModQueueRow`:
  - Type chip + age (`<n>h ago`).
  - Title (`titleMedium`).
  - Reporter handle pill: `User_xxxx` (masked username — see `design-review.md` decision 3).
  - `<n> evidence` count.
  - `Review` primary button on the right → `admin-review` with the report payload.
  - **Flagged variant**: row gets a left coral-amber border + a `Team note: …` line beneath the row showing the team-internal note.
- **`BottomNav`** (admin variant — 3rd tab is `Moderate` and is active here).

## States

- **Empty** — muted icon + `Queue is empty — nice work!` (admin-flavoured copy).
- **Loading** — skeleton rows.
- **Error** — banner above list.

## Interactions

- Tap row anywhere (or `Review` button) → `admin-review`.
- Sort dropdown → re-sort (oldest-first by default; FR-7.2).
- Priority flag chip → filter to flagged only.

## Role variants

This screen is admin-only. Other roles get a 404-style "You don't have access" page if they deep-link here (or — preferred — the route guard simply pushes them to `home` with a toast).

## Notes

- Reporter handles use `User_<4 hex>` masked format. Per `design-review.md` decision 3, ratifying this means adding a `users.public_handle` column. Until then, derive on the client from `users.id`.
- Stats refresh on every queue mutation (approve/reject/flag) so the counts stay live.
