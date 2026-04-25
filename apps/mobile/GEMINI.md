# GEMINI.md — `apps/mobile`

Flutter app. **Feature-first layout**.

## Layout & Patterns

- **Feature-first**: `lib/features/<feature>/{data,domain,presentation}`.
  - `domain/`: pure Dart entities + use cases. No Flutter imports.
  - `data/`: repositories, API clients.
  - `presentation/`: widgets + Riverpod providers.
- **Core**: Contains theme, router (`GoRouter`), DI, and `api_types/` (generated Dart types).
  - `lib/core/api_client.dart`: HTTP client provider.
  - `lib/core/cache/app_database.dart`: drift (SQLite) DB.
  - `lib/core/di/`: providers for Firebase, Auth, Analytics, Messaging, Cache.
- **State Management**: Riverpod 2.
- **Routing**: `go_router`.

## Local Persistence

Pick the layer that fits:
- **SharedPreferences** (`sharedPreferencesProvider`): For primitives like theme, language.
- **FlutterSecureStorage** (`secureStorageProvider`): Encrypted storage for sensitive data like tokens.
- **AppDatabase (drift)** (`appDatabaseProvider`): Structured data like cache entries and drafts.
  - Run `dart run build_runner build` after editing tables.

## Style Rules

- **Small widgets**: Extract any widget over ~80 lines.
- **Const constructors**: Use `const` wherever they compile.
- **No business logic in widgets**: Push to domain / data layers.
- **No `print`**: Lints block it. Use appropriate logging.
- **Firebase**: Initialized at startup. FCM permission prompt fires at startup.

## Commands

- `flutter run` — launch on an attached device / simulator
- `flutter test` — run unit and widget tests
- `dart analyze && flutter test` — run full PR test suite
- `dart analyze` — run linter
- `dart format .` — format code
