# my-reports — Submission history

**PRD:** FR-6.1, FR-6.2 / P-11  **Roles:** user, admin
**Flutter:** `apps/mobile/lib/features/reports/presentation/my_reports_screen.dart` (planned)

**Snapshot:** `../snapshots/user/my-reports.txt` · **Screenshot:** `../screenshots/user/my-reports.png`

## Purpose

Reporter-facing list of their own submissions, grouped by status, with edit/withdraw actions while pending.

## Layout

- Top bar: back arrow + title `My reports`.
- **`FilterChipBar`** with status counts: `All`, `Pending (n)`, `Verified (n)`, `Rejected (n)`, `Flagged (n)`.
- **List** of report rows:
  - **Status pill** at top of each row, coloured by status:
    - `Pending` → amber (`VerdictPalette.suspicious`)
    - `Verified` → green (`VerdictPalette.safe`)
    - `Rejected` → red (`VerdictPalette.scam`)
    - `Flagged` → amber (per FR-6.1, surface as Pending — see Notes)
  - Date right-aligned (`MM-DD`).
  - Title (`titleMedium`).
  - Type (`bodySmall`, muted).
  - **Pending** rows have inline `Edit` and `Withdraw` text buttons.
  - **Rejected** rows show `Moderator note: …` callout (muted surface card with the rejection reason).
  - **Flagged** rows show `Under team review. We'll let you know once a decision is made.` callout.
- **`BottomNav`**.

## States

- **Empty** — muted icon + `You haven't submitted any reports yet.` + `Submit a report` link.
- **Loading** — 2 skeleton rows.

## Interactions

- Tap row → `report-detail` (read-only) or `submit-report` step 1 with payload (when row is Pending and user taps `Edit`).
- `Edit` → `submit-report` editing the existing draft (status remains `Pending`).
- `Withdraw` → confirm dialog → `DELETE /reports/:id`. Row disappears.

## Role variants

None (admins also see their own submissions here, separate from the moderation queue).

## Notes / divergences

- **`design-review.md` decision 2:** prototype shows `Flagged` directly to the reporter, contradicting FR-6.1. The Flutter app must always map `flagged → "Pending"` for reporter-facing views. The "Under team review…" callout is fine — surface that as the Pending row's inline note instead of a separate `Flagged` chip.
- Counts in the chip labels stay in sync with filtered-list counts.
- Date format: `MM-DD` per row (matches `feed`).
