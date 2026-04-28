# alerts — Announcements list

**PRD:** FR-8.1 / P-05  **Roles:** all
**Flutter:** `apps/mobile/lib/features/alerts/presentation/alerts_screen.dart` (planned)

**Snapshot:** `../snapshots/user/alerts.txt` · **Screenshot:** `../screenshots/user/alerts.png`

## Purpose

Vertical list of admin-published announcements: fraud alerts, tips, platform updates. Filterable by category.

## Layout (top-down)

- Top bar: title `Announcements` + back arrow when entered from a deep-link.
- **`FilterChipBar`**: `All`, `Fraud Alert`, `Tips`, `Platform Update`. Active chip = primary fill.
- **Announcement list** — vertical of `AlertCard`s:
  - Category chip with category-tinted background:
    - `Fraud Alert` → red (`VerdictPalette.scam`)
    - `Tips` → green (`VerdictPalette.safe`)
    - `Platform Update` → primary coral
  - Date right-aligned (`MM-DD`).
  - Title (`titleMedium`, w700).
  - Excerpt (2 lines, muted).
- **`BottomNav`**.

## States

- Empty: muted icon + `No announcements yet.`
- Loading: 3 skeleton cards.
- Pull-to-refresh.

## Interactions

- Tap a card → `announcement-detail` with payload.
- Filter chip → narrow list.

## Role variants

None for the list itself. Admins can additionally enter the `announcement-editor` from a "+" FAB (TBD — capture when wiring A-03).

## Notes

- Sample copy claims "AI Search supports voice + screenshots" — `design-review.md` flags this as placeholder copy not to seed in production (decision 5).
- Forwarding to 1185 (TruePalice) is referenced in `announcement-detail`; cross-link there.
