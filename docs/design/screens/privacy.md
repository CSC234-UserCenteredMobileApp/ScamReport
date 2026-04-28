# privacy — Privacy Policy

**PRD:** P-07  **Roles:** all
**Flutter:** `apps/mobile/lib/features/legal/presentation/privacy_screen.dart` (planned)

**Snapshot:** `../snapshots/user/privacy.txt` · **Screenshot:** `../screenshots/user/privacy.png`

## Purpose

Static legal text. Reachable from `me`, registration consent block, and any deep-link.

## Layout

- Top bar: back arrow + title `Privacy Policy`.
- Scrollable column body — `LegalDoc` widget:
  - `Last updated: April 25, 2026` (muted `bodySmall`).
  - Numbered sections (H2 + body paragraphs):
    1. **What we collect** — email, report content, search queries; explicit "we never collect contact list, location history, SMS bodies".
    2. **How we use it** — moderated reports public without identity; queries logged for abuse only.
    3. **Your rights (PDPA)** — access / correction / deletion; 7-day purge after deletion request.
    4. **On-device processing** — Android-only smishing detection extracts identifiers, never raw SMS body.
- **`BottomNav`**.

## States

- Always populated. Plain static document.
- Source-of-truth lives in a Markdown file (or JSON) bundled with the app; do not paste prose into a Dart string.

## Interactions

- None beyond scroll.

## Role variants

None.

## Notes

- TH translation must exist (FR §6.4). Pull from the same Localizations bundle that drives all other strings.
- The `Last updated:` date should be sourced from the legal doc's frontmatter, not hard-coded.
