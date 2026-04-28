# home — Personalised hero + stats + recent alerts

**PRD:** entry-point screen (no PRD ID)  **Roles:** all
**Flutter:** `apps/mobile/lib/features/home/presentation/home_screen.dart` (planned)

**Snapshot:** `../snapshots/user/home.txt` · **Screenshot:** `../screenshots/user/home.png` (also `guest/home.png`, `admin/home.png` for variants)

## Purpose

Lands here after sign-in (and for guests). Surfaces clipboard banner, primary check input, weekly stats, recent alerts, and recently-verified reports.

## Layout (top-down)

1. **`BrandHeader`** — avatar pill (initials for logged-in, generic icon for guest) + greeting.
   - Guest copy: `Hi 👋` / `Stay one step ahead of scams`
   - User/admin copy: `Hi, <name> 👋` / `Stay one step ahead of scams`
2. **`ClipboardBanner`** (FR-9.2) — coral-tinted card, shown only when clipboard contains a phone/url-like value.
   - Copy: `We noticed something on your clipboard` / `<value>`
   - Buttons: `Check it` (primary) → `verdict` with payload; `×` (dismiss).
3. **Search input** — `TextField` with shield icon prefix, placeholder `Paste a number, link, or message…`. Submitting → `verdict`. (Variant — see Notes.)
4. **`AI search` button** — outlined card with sparkle icon → `search`.
5. **`THIS WEEK` section** — uppercase label + `Updated <hh:mm>`. Below: 3-up `StatCardRow` with `2,184 / Verified reports`, `+36 / New this week`, `SMS phishing / Top scam type`.
6. **`RECENT FRAUD ALERTS` section** — uppercase label + `See all` link → `alerts`. Below: 2 most recent `AlertCard`s.
7. **`RECENTLY VERIFIED` section** — uppercase label + `See all` link → `feed`. Below: 2 most recent `ReportCard`s.
8. **`BottomNav`** — `Home / Feed / Report \| Moderate / Alerts / Me`.

## States

- **Clipboard banner** present only when applicable; dismiss persists for the session.
- **Stats** show a "Updated <time>" timestamp. Stale → still display, no special state.
- No empty/error variant — alerts and reports lists fall back to "—" if there's no data.

## Interactions

| Tap | Goes to |
| --- | --- |
| Search input submit | `verdict` (with `runCheck` flow) |
| `AI search` | `search` |
| `Check it` (clipboard) | `verdict` with clipboard value as payload |
| `×` (clipboard) | dismiss banner for session |
| Alert card | `announcement-detail` |
| Report card | `report-detail` |
| `See all` (alerts) | `alerts` |
| `See all` (reports) | `feed` |
| Bottom nav | corresponding screen |

## Role variants

| Field | Guest | User | Admin |
| --- | --- | --- | --- |
| Greeting | `Hi 👋` (generic) | `A` avatar + `Hi, Anya 👋` | same as user |
| Bottom nav 3rd tab | `Report` (gates submit) | `Report` | `Moderate` (→ `mod`) |

## Notes / open questions

- Two layout variants exist in the prototype: **search-led** (the captured one) and **panic big-button** (single-action focus). `design-review.md` flags this as decision 6 — pick before building.
- `+36 New this week` value uses primary coral colour (semantic: "trending up"). All other stat numbers stay neutral.
- Top scam type cell shows two-line text (`SMS` / `phishing`) — split on space inside the card.
