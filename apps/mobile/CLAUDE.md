# CLAUDE.md — `apps/mobile`

Flutter app. Feature-first layout: everything for a feature lives in `lib/features/<feature>/{data,domain,presentation}`. Cross-cutting concerns live in `lib/core/`.

## Layout

- `lib/core/theme/` — `ThemeData`, color tokens
- `lib/core/router/` — `GoRouter` configuration
- `lib/core/api_client.dart` — base URL + http client provider
- `lib/core/cache/app_database.dart` — drift (SQLite) DB + `CacheEntries`/`Drafts` tables; `app_database.g.dart` is committed codegen output
- `lib/core/di/firebase.dart` — `initializeFirebase()` (called from `main.dart` before `runApp`)
- `lib/core/di/auth.dart` — `firebaseAuthProvider`, `authStateProvider`
- `lib/core/di/analytics.dart` — `firebaseAnalyticsProvider`
- `lib/core/di/messaging.dart` — `firebaseMessagingProvider`, `fcmTokenProvider`, `fcmForegroundMessagesProvider`
- `lib/core/di/cache.dart` — `appDatabaseProvider`, `sharedPreferencesProvider`, `secureStorageProvider`
- `lib/core/api_types/` — **generated** Dart types from `packages/shared` (via `./scripts/codegen.sh`)
- `lib/features/<feature>/domain/` — entities + use cases; **pure Dart, no Flutter imports**
- `lib/features/<feature>/data/` — repositories, API clients
- `lib/features/<feature>/presentation/` — widgets + Riverpod providers

## Choices

- **State: Riverpod 2** — compile-safe DI, testable without `BuildContext`.
- **Routing: go_router** — URL-first declarative routing.
- **Firebase** — `main()` awaits `initializeFirebase()` before `runApp`. If Firebase config files are missing, init logs a warning and returns false; the rest of the app still works (Crashlytics handlers just aren't wired). Config files (`google-services.json`, `GoogleService-Info.plist`) are **not committed**; see `HOW_TO_CONTRIBUTE.md` §3.
- **FCM permission prompt fires at startup.** If you'd rather defer the prompt until the user opts in, move `requestPermission(...)` out of `initializeFirebase()` and into the screen that asks for it.
- **Local persistence** — three layers, pick the smallest one that fits:
  - `SharedPreferences` (`sharedPreferencesProvider`) — primitives only (bool, int, String, List<String>). Use for theme, language, "has seen onboarding".
  - `FlutterSecureStorage` (`secureStorageProvider`) — encrypted at rest. Use for refresh tokens or anything sensitive.
  - `AppDatabase` / drift (`appDatabaseProvider`) — anything queryable, structured, or large. Cached API responses (`CacheEntries`) and user drafts (`Drafts`) live here. Re-run `dart run build_runner build` after editing tables.

## Style

- Small widgets. Extract any widget over ~80 lines.
- `const` constructors wherever they compile — the lint enforces this.
- No business logic in widgets — push to domain / data layers.
- No `print` (lint blocks it).

## Commands

- `flutter run` — launch on an attached device / simulator
- `flutter test` — unit + widget tests
- `dart analyze` — lint
- `dart format .` — format
