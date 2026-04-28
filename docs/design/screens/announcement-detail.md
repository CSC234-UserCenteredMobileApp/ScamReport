# announcement-detail — Announcement at shareable URL

**PRD:** FR-8.2 / P-06  **Roles:** all
**Flutter:** `apps/mobile/lib/features/alerts/presentation/announcement_detail_screen.dart` (planned)

**Snapshot:** `../snapshots/user/announcement-detail.txt` · **Screenshot:** `../screenshots/user/announcement-detail.png`

## Purpose

Full body of a single announcement. Has a public, shareable deep-link.

## Layout

- Top bar: back arrow + share button.
- **Category chip** at top (Fraud Alert / Tips / Platform Update — same colour rules as `alerts`).
- **Title** (`headlineSmall`, w700).
- **Meta line**: `<yyyy-mm-dd> • Posted by ScamReport Team` (muted `bodySmall`).
- **Body** — long-form text. Supports paragraphs and bullet lists (the prototype uses `•` bullet glyph). No images in current sample.
- **`BottomNav`**.

## States

- Always populated when reached. Deep-link entry must handle `id-not-found` → toast + route back to `alerts`.

## Interactions

- Share → native share sheet with the public URL (FR-8.2).
- Back → `alerts` (or wherever the user came from).

## Role variants

None for viewers. Admins can edit via `announcement-editor`; there is no "Edit" CTA on this screen in the current prototype, but adding one for admin role would be reasonable (TBD).

## Notes

- The sample body uses inline glyph bullets (`• `). Render as a real `ListView` of `ListTile`s? Or just preserve the markdown-like prose? Recommend prose with a custom paragraph parser that detects `\n• ` and renders as `<li>`-style bullets.
- Date format here is full `yyyy-mm-dd` (matches `report-detail`).
