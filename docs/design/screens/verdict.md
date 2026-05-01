# verdict — Traffic-light verdict

**PRD:** FR-2.2 / P-13  **Roles:** all (FR-2.4 — verdict reachable for guests)
**Flutter:** `apps/mobile/lib/features/verdict/presentation/verdict_screen.dart` (planned)

**Snapshots:** `../snapshots/user/verdict-{scam,suspicious,safe,unknown}.txt`
**Screenshots:** `../screenshots/user/verdict-{scam,suspicious,safe,unknown}.png`

## Purpose

Show a single-glance verdict (Scam / Suspicious / Safe / Unknown) for whatever identifier the user just checked. Surfaces matched-reports count and a "Report this" CTA that pre-populates `submit-report`.

## Layout

- **Loading state** (~1.5s):
  - Title `Checking…`
  - Subtitle `Cross-checking 2,184 verified reports…`
  - Body `Hashing identifier on-device, then matching against our verified database.` (muted)
- **Resolved state**:
  - Top bar: back arrow only (no title)
  - **`VerdictPill`** filling top half: large icon + verdict label (`Scam` / `Suspicious` / `Safe` / `Unknown`). Background uses `VerdictPalette.<verdict>.bg`, foreground uses `.fg`.
  - Subtitle copy per verdict:
    - **scam** → `Multiple verified reports match this item.`
    - **suspicious** → `Partial match — proceed with caution.`
    - **safe** → `No verified scam reports for this item.`
    - **unknown** → `We could not classify this item.`
  - For scam/suspicious: `<n> verified reports matched` line below the subtitle.
  - **`YOU CHECKED`** uppercase label + the queried identifier (`+66 84 419 2270` etc.) in mono-ish weight, wrapped in a subtle surface chip.
  - **`See matched reports`** secondary button (only when matches > 0) → `feed` filtered by identifier.
  - **`Report this`** secondary button — pre-fills `submit-report` with the query value as `target_identifier`.
- No bottom nav (flow-only).

## States

| State | Surfaces |
| --- | --- |
| `scam` | red palette, "See matched reports", "Report this", count |
| `suspicious` | amber palette, same buttons, count |
| `safe` | green palette, only "Report this" (no count) |
| `unknown` | slate palette, only "Report this" (no count) |
| `loading` | spinner + check copy (~1.5s) |

## Interactions

- `See matched reports` → `feed` with `?target=<id>` filter (if FR supports it; otherwise plain feed).
- `Report this` → `submit-report` with `prefill: { target_identifier, scam_type? }`.
- Back arrow → pop to whatever screen called us (`home` / `check-input` / clipboard banner).

## Role variants

None. FR-2.4 mandates accessibility for guests. The "Report this" CTA still routes to `submit-report`, where guests will see the sign-in gate.

## Notes / open questions

- Layout is **full-bleed**: verdict colour fills the whole screen top-to-bottom. Decision 6 in `design-review.md` is locked — do not implement the card variant.
- Per PRD §6.4 colour is never the only differentiator → always pair the verdict colour with an icon AND the verdict label text.
- Loading copy mentions on-device hashing — confirm with the FR-2 implementation; if untrue, soften the copy ("Looking this up…") to avoid making a privacy claim we don't keep.
