# terms — Terms of Service

**PRD:** P-08  **Roles:** all
**Flutter:** `apps/mobile/lib/features/legal/presentation/terms_screen.dart` (planned)

**Snapshot:** `../snapshots/user/terms.txt` · **Screenshot:** `../screenshots/user/terms.png`

## Purpose

Static legal text. Reachable from `me`, registration consent block, and deep-link.

## Layout

Same `LegalDoc` shell as `privacy`. Top bar title is `Terms of Service`.

## States

Same as `privacy`.

## Interactions

None beyond scroll.

## Role variants

None.

## Notes

- The prototype's `terms` body is a placeholder copy of the privacy text. Do **not** ship that. Substitute the real ToS Markdown when bundling.
- Same Localizations + frontmatter rules as `privacy.md`.
