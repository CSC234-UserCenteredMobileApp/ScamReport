# search — AI semantic search

**PRD:** FR-4.1–FR-4.5 / P-09  **Roles:** user, admin (gated for guest)
**Flutter:** `apps/mobile/lib/features/search/presentation/search_screen.dart` (planned)

**Snapshots:** `../snapshots/user/search.txt` (real), `../snapshots/guest/search.txt` (gate)
**Screenshots:** `../screenshots/user/search.png`, `../screenshots/guest/search.png`

## Purpose

Natural-language search across report corpus. Results are ranked relevance cards — **not** verdicts. (FR-4.4 — explicit non-verdict tool.)

## Layout (logged-in)

- Top bar: title `AI Search`.
- Body line under title: `This is a discovery tool — it surfaces similar reports, but does not give a Scam/Safe verdict.` (muted `bodySmall`, important — keeps users from misreading results as verdicts).
- **Search input** — multi-line text area, placeholder `Describe what happened…`. Submit triggers query.
- **`TRY ASKING`** uppercase label + 3 example queries as tappable chips:
  - `Someone called pretending to be from the Revenue Department`
  - `Parcel-held message from Kerry with a link`
  - `LINE friend asking for OTP from "bank security"`
- After submit: scrollable list of result cards (relevance score badge + report title + excerpt). Not captured in current snapshot — capture and document when wiring.
- **`BottomNav`**.

## Layout (guest)

`EmptyGate` panel:
- Heading `Sign up to use AI Search`
- Body `Ask a natural-language question about a scam — like "parcel held SMS from Kerry" — and find similar past reports.`
- Buttons: `Create free account` (primary) → `register`; `Maybe later` (text) → back.
- `BottomNav` still visible.

## States

- **Idle** — example chips visible.
- **Querying** — input replaced with shimmering "Searching…" line; `EmptyGate` is not shown.
- **Empty results** — `No similar reports yet — try another phrasing.` Reuse the search-led empty pattern.
- **Error** — toast, keep input.
- **Guest** — see Layout (guest) above.

## Interactions

- Tap example chip → fill input + auto-submit.
- Submit → call `/search/semantic` (FR-4.x) → render result cards.
- Tap result card → `report-detail`.

## Role variants

| Role | Behaviour |
| --- | --- |
| Guest | `EmptyGate` (no search input) |
| User | Full screen |
| Admin | Full screen (same as user) |

## Notes

- FR-4.4: result cards must NOT show a Scam/Safe verdict label. Show only type + relevance + excerpt.
- Per `design-review.md` decision 5: don't seed "AI Search supports voice + screenshots" — placeholder copy only.
