# Share Target Feature — Design Spec

**Date:** 2026-05-12  
**PRD ref:** FR-9 (clipboard / share surface), FR-2.2 (verdict), FR-2.4 (guests)  
**Feature flag key:** `enable_share_target`  
**Platform:** Android only (`kIsWeb` guard not needed — share intent never fires on web)

---

## Problem

Users encounter potential scam messages in WhatsApp, LINE, SMS, or browsers and must manually copy-paste them into ScamReport. An Android share target removes that friction.

---

## Flow

```
User highlights text in any app → Share → ScamReport
         │
         ├── feature flag off → no-op, app opens normally
         │
         ├── not authenticated → notification: "Sign in to check this"
         │                        tap → /login
         │
         └── authenticated
                  ├── detect input kind (phone / url / text)
                  ├── fire "Checking…" notification immediately
                  ├── POST /check  (existing endpoint, no changes)
                  └── replace notification with verdict
                           tap → /verdict?q=<encoded>&kind=<kind>
```

## SMS forward

After verdict resolves, "Share via SMS" (`OutlinedButton.icon`) shown only for `scam` and `suspicious` results. Taps `sms:?body=...` via `url_launcher`. Opens the user's native SMS app with a pre-filled message.

---

## Architecture

### New files

| File | Purpose |
|---|---|
| `features/share_target/domain/share_input.dart` | Value object: `text` + `kind`. `detectKind(raw)` static method. |
| `features/share_target/data/share_intent_service.dart` | Wraps `ReceiveSharingIntent`. Emits `ShareInput` stream + cold-start initial. |
| `features/share_target/presentation/share_target_handler.dart` | Orchestrator: auth check → check API → local notification. Static `init(ref)` entry point. |
| `features/share_target/presentation/share_target_providers.dart` | `shareIntentServiceProvider`. Re-exports `featureFlagProvider`. |

### Modified files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `receive_sharing_intent: ^1.8.1`, `url_launcher: ^6.3.2` |
| `AndroidManifest.xml` | Add `ACTION_SEND text/plain` intent-filter + `sms:` scheme in `<queries>` |
| `core/router/app_router.dart` | Register `setShareNotificationNavigator`; update `/verdict` to accept `?q=&kind=` query params |
| `main.dart` | Convert `MyApp` to `ConsumerStatefulWidget`; call `ShareTargetHandler.init(ref)` post first-frame |
| `check/presentation/verdict_screen.dart` | Add "Share via SMS" button for scam/suspicious verdicts |
| `l10n/app_en.arb` + `app_th.arb` | Add `verdictShareViaSms` key |

### No API changes

`POST /check` accepts `text`, `url`, and `phone` input kinds — all three covered by `ShareInput.detectKind`.

---

## Input detection (client-side)

```dart
static String detectKind(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'text';
  if (RegExp(r'^\+?[\d\s\-\(\)]{7,}$').hasMatch(t)) return 'phone';
  if (RegExp(r'https?://|www\.').hasMatch(t)) return 'url';
  return 'text';
}
```

Server re-normalises regardless; this just populates `CheckQuery.type`.

---

## Notification design

| State | Title | Body |
|---|---|---|
| Share received + authed | `Checking…` | Input truncated to 60 chars |
| Verdict returned (scam) | `⚠️ Scam` | `"<input>" — tap to see details` |
| Verdict returned (suspicious) | `⚠️ Suspicious` | `"<input>" — tap to see details` |
| Verdict returned (safe) | `✓ Safe` | `"<input>" — tap to see details` |
| Not authenticated | `Sign in to check this` | Input truncated to 60 chars |
| Check failed | `Check failed` | `Could not analyse…` |

- Channel: `share_check_results`, importance HIGH
- Notification ID `42` — always replaces prior share notification (no stacking)
- Notification body never stores full text; truncated at 60 chars

---

## Privacy

- Shared text sent to `POST /check` only — not persisted locally by the handler
- Server writes a `check_logs` row (existing behaviour, same as manual check)
- Notification body truncated to 60 chars
- `CheckQuery.source = 'share'` for analytics

---

## Dependencies added

| Package | Version | Reason |
|---|---|---|
| `receive_sharing_intent` | `^1.8.1` | Android `ACTION_SEND text/plain` intent |
| `url_launcher` | `^6.3.2` | Open `sms:` URI for SMS forward |
| `flutter_local_notifications` | already `^18.0.0` | Verdict notification |
| `POST_NOTIFICATIONS` permission | already in manifest | Android 13+ |

---

## Tests

| File | Coverage |
|---|---|
| `test/features/share_target/share_input_test.dart` | `detectKind` for phone / url / text / edge cases |
| `test/features/share_target/share_target_handler_test.dart` | `truncateForNotification`, `verdictNotificationLabel` |
| `test/features/check/verdict_screen_test.dart` | SMS button visible for scam/suspicious, hidden for safe/unknown |
