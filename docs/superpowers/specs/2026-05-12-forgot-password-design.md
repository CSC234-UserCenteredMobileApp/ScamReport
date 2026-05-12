# Forgot Password Feature — Design Spec

**Date:** 2026-05-12  
**PRD ref:** FR-2.1 (auth — email/password sign-in)  
**Platform:** Android + Web (no platform guard needed — Firebase Auth works everywhere)

---

## Problem

The login screen has a "Forgot password?" button that shows a placeholder snackbar. Users who lose their password have no self-service recovery path.

---

## Flow

```
Login screen — tap "Forgot password?"
        │
        └── /forgot-password
                 │
                 ├── email field + "Send reset link" button
                 │
                 ├── [submit] → Firebase sendPasswordResetEmail(email)
                 │         ├── success (incl. user-not-found*) → success state
                 │         └── error → ErrorBanner
                 │
                 └── success state
                          "Check your email" heading
                          Body: "If an account exists for <email>, a reset link has been sent."
                          "Back to login" FilledButton → context.pop()
```

*`user-not-found` shows success state (same as real success) to prevent email enumeration.

---

## Architecture

No new domain entity or Riverpod provider. Local state only — identical pattern to `LoginScreen`.

### New file

| File | Purpose |
|---|---|
| `features/auth/presentation/forgot_password_screen.dart` | Screen: email form → success view |

### Modified files

| File | Change |
|---|---|
| `features/auth/data/auth_repository.dart` | Add `sendPasswordResetEmail(String email)` |
| `features/auth/presentation/login_screen.dart` | Wire "Forgot password?" to `context.push('/forgot-password')`; remove placeholder snackbar method |
| `core/router/app_router.dart` | Add `GoRoute(path: '/forgot-password', ...)` outside the shell |

---

## Screen states

### Form state (`_sent = false`)

```
AuthScaffold tagline: "Reset your password"

[email field — keyboard: emailAddress, autofill: email]

[Send reset link]   ← FilledButton; disabled + spinner while _busy

[ErrorBanner]       ← only shown when _error != null
```

### Success state (`_sent = true`)

```
AuthScaffold tagline: "Check your email"

  🔒  (lock_outline icon, 48 px, primary-tinted circle)

  "We've sent a password reset link to"
  "<email>"                 ← bold

  [Back to login]           ← FilledButton → context.pop()
```

---

## Error mapping

| Firebase code | User message |
|---|---|
| `invalid-email` | "That email looks invalid." |
| `user-not-found` | *(silent — show success state)* |
| `too-many-requests` | "Too many attempts. Please try again in a moment." |
| `network-request-failed` | "Network error. Check your connection." |
| *(other)* | "Something went wrong. Please try again." |

---

## Tests

| File | Coverage |
|---|---|
| `test/features/auth/forgot_password_screen_test.dart` | Success state shown after submit; error banner on Firebase error; send button disabled while loading; "Back to login" triggers pop |
