# me — Settings

**PRD:** P-12 / FR-10.2  **Roles:** all
**Flutter:** `apps/mobile/lib/features/settings/presentation/settings_screen.dart` (planned)

**Snapshots:** `../snapshots/{guest,user,admin}/me.txt`
**Screenshots:** `../screenshots/{guest,user,admin}/me.png`

## Purpose

Account state, notification toggles, language/theme preferences, links to legal docs and (when authed) sign-out.

## Layout (top-down)

- Top bar: title `Settings`.
- **Account row** (varies by role — see Role variants).
- **`NOTIFICATIONS`** uppercase section label, then 3 `SwitchListTile`s:
  - `Phone scam alerts` / sub: `Get notified about new phone scams`
  - `SMS phishing alerts` / sub: `Trending SMS scam patterns`
  - `Regional alerts` / sub: `Scams reported in your province`
- **`PREFERENCES`** section label:
  - **Language** row → segmented `English / ภาษาไทย`. (Note: TH should be default — `design-review.md` divergence.)
  - **Theme** row → segmented `Light / Dark`.
- **`ACCOUNT`** section label:
  - `My reports` row (chevron) → `my-reports`. Hidden for guest.
  - `Privacy policy` row → `privacy`.
  - `Terms of service` row → `terms`.
  - `Sign out` row (when authed) → confirm dialog → `signOut()` → `home`.
- App version footer: `ScamReport v1.0 • KMUTT SIT` (muted `bodySmall`, centered).
- **`BottomNav`**.

## Role variants

| Element | Guest | User | Admin |
| --- | --- | --- | --- |
| Account row | "Guest" + "Not signed in" + `Sign in` button | Avatar `A` + `Anya` + `anya@example.com` | same as user + `Admin` badge under email |
| `My reports` row | hidden | shown | shown |
| `Sign out` row | hidden | shown | shown |

## States

- **Notifications** — independent toggles persisted via API (FR-8.x).
- **Language / theme** — persisted in app preferences, applied immediately.
- **Sign out** — confirm dialog `Sign out of ScamReport?`; on confirm, FirebaseAuth `signOut`, return to `home` (which router will redirect to `login` if `home` becomes auth-required).

## Interactions

- All rows are tappable; outlined chevron when navigation, switch when toggle.

## Notes

- The `Admin` badge for admin role is small uppercase chip with primary tint (analogous to a verdict pill but role-coloured).
- Guest variant's `Sign in` is the same auth entry as everywhere else; route to `/login`.
