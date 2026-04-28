# login — Sign in / register

**PRD:** FR-1.1 / P-01  **Roles:** guest entry point
**Flutter:** `apps/mobile/lib/features/auth/presentation/login_screen.dart` (built — see also `register_screen.dart`)

**Snapshot:** `../snapshots/user/login.txt` · **Screenshot:** `../screenshots/user/login.png`

## Purpose

Email + password sign-in for returning users; secondary CTA to register; Google sign-in option.

## Layout

Already shipped in `login_screen.dart` using `AuthScaffold` (brand pill + wordmark + tagline). Prototype tagline is `Welcome back`.

- `AuthScaffold` header
- Body line: `Sign in to continue protecting your community.` (muted `bodyMedium`)
- Email field (`Icons.mail_outline` prefix, autofill `email`)
- Password field via `PasswordField` (show/hide toggle)
- Right-aligned `TextButton` → "Forgot password?" → snackbar "Password reset is coming soon — contact support for now."
- Primary CTA `Sign in` (full-width `FilledButton`)
- Divider: centered `OR` line
- Secondary CTA: `Continue with Google` (outlined button with Google glyph)
- Footer link: `New here? ` + `Create account` (bold primary) → routes `/register`

## States

- **Idle**: form editable, button enabled when fields valid.
- **Loading**: `AbsorbPointer` wraps form; `Sign in` button shows spinner.
- **Error**: `ErrorBanner` (`VerdictPalette.scam` tones) above the button. Map FirebaseAuth codes per existing `_mapFirebaseError`.

## Interactions

- Submit → `signInWithEmail`. On success → `context.go('/')`.
- Google → not yet wired.
- Footer → `/register`.

## Role variants

None.

## Notes

Already implemented; this spec exists to document the intended copy + flow. The Google sign-in button is currently a stub; wire when FR-1.1 is fully delivered.
