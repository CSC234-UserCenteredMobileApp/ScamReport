# feed — Verified reports feed

**PRD:** FR-3.1 / P-03  **Roles:** all
**Flutter:** `apps/mobile/lib/features/feed/presentation/feed_screen.dart` (planned)

**Snapshot:** `../snapshots/user/feed.txt` · **Screenshot:** `../screenshots/user/feed.png`

## Purpose

Browseable list of verified scam reports, with weekly aggregate stats and scam-type filter. The reporter is never displayed (FR-3.4).

## Layout (top-down)

- Top bar: title `Verified feed`, right-aligned filter `Icons.tune` button (opens advanced filter sheet — not captured).
- **`StatCardRow`** (3-up): `2,184 / TOTAL`, `+28 / THIS WEEK`, `SMS phishing / TOP TYPE`.
- **`FilterChipBar`** — horizontal scrollable: `All`, `Phone Impersonation`, `Phishing SMS`, `Fake QR Code`, `E-commerce Fraud`, `Investment Fraud`, `Romance Scam`. Active chip = primary fill.
- **Report list** — vertical, infinite-scroll, of `ReportCard`s:
  - Type chip (uses scam-type accent colour) + date (right-aligned `MM-DD`)
  - Title (`textTheme.titleMedium`, w700)
  - Excerpt (2 lines max, muted `bodyMedium`)
  - `<count> reports` line at bottom (muted, with people icon)
- **`BottomNav`** at bottom.

## States

- **Empty state** — list area shows muted icon + `No reports yet — be the first to submit one.` Reuse `EmptyGate` shape with link to `submit-report`.
- **Loading** — skeleton 3 cards.
- **Error** — toast / banner; keep last-good list visible.

## Interactions

- Filter chip tap → narrow list to that scam type. `All` resets.
- Filter icon → bottom sheet with advanced options (date range, target type) — TBD; capture later.
- Tap a `ReportCard` → `report-detail` with the report payload.

## Role variants

None for content. Bottom nav 3rd tab differs (Report vs Moderate) per role.

## Notes

- Six scam types in prototype; **DB seed has 5**. `design-review.md` decision 1 — adopt the design's six (with longer DB slugs e.g. `phone_impersonation`). Update sample data when implementing.
- Date format is `MM-DD` per card; show full date in `report-detail`.
- "Total / This week / Top type" stats refresh hourly per FR-3.2.
