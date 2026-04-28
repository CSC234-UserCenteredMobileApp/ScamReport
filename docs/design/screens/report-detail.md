# report-detail — Verified report detail

**PRD:** FR-3.4 / P-04  **Roles:** all
**Flutter:** `apps/mobile/lib/features/reports/presentation/report_detail_screen.dart` (planned)

**Snapshot:** `../snapshots/user/report-detail.txt` · **Screenshot:** `../screenshots/user/report-detail.png`

## Purpose

Full body of a verified scam report. Reporter is never displayed (FR-3.4) — only the scam content and aggregate count.

## Layout (top-down)

- Top bar: back arrow + share button (right).
- **Verified pill**: green chip with `Icons.verified_outlined` and label `Verified`. Followed by type chip (e.g. `Phishing SMS`).
- **Title** (`textTheme.headlineSmall`, w700): `Fake Kerry parcel SMS with phishing link`.
- **Meta row**: `📅 Verified <yyyy-mm-dd>` + `👥 <n> reports`.
- **`⚠ REPORTED IDENTIFIER`** uppercase label + identifier in a chip (e.g. `kerry-th-track[.]net`). Long values wrap; mono-ish typography for clarity.
- **`WHAT HAPPENED`** uppercase label + paragraph body (`bodyMedium`).
- **`EVIDENCE`** uppercase label + `EvidenceList` (e.g. `Screenshot 1`, `Screenshot 2`). Tap → preview (mocked).
- **Primary CTA**: `Report a similar scam` (full-width `FilledButton`) → `submit-report` with `prefill.scam_type` set.
- **Privacy footer** (muted `bodySmall`): `The reporter's identity is never shown publicly. Only the scam content above is shared.`
- **`BottomNav`** at bottom.

## States

- Always populated for a verified report.
- Loading: skeleton sections (title, meta, body) — uncommon since cached from `feed`.

## Interactions

- Share (top right) → native share sheet with deep-link to this report.
- Evidence row → image preview overlay (mocked).
- `Report a similar scam` → `submit-report` with prefill.
- Back → pop.

## Role variants

None. Same content for guest / user / admin.

## Notes

- Identifier display: phone numbers should be space-formatted (`+66 84 419 2270`); URLs should be defanged with bracketed dots (`kerry-th-track[.]net`).
- Date format: full `yyyy-mm-dd` here (vs. `MM-DD` on `feed` cards).
