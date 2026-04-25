---
description: Scaffold a new Flutter feature folder with data/domain/presentation layers
---

Create a new Flutter feature named: $ARGUMENTS

Follow these steps:

1. **Create the feature folders** under `apps/mobile/lib/features/<feature>/`:
   - `domain/` — entities and use cases. Pure Dart, no Flutter imports.
   - `data/` — repositories and API clients. Imports generated types from `core/api_types/`.
   - `presentation/` — widgets and Riverpod providers.

2. **Add one file per layer to start:**
   - `domain/<feature>_entity.dart` — the main entity or value object
   - `data/<feature>_repository.dart` — repository interface + implementation
   - `presentation/<feature>_screen.dart` — the top-level screen widget
   - `presentation/<feature>_providers.dart` — Riverpod providers for this feature

3. **Wire routing** in `apps/mobile/lib/core/router/` — add the screen's route to the `GoRouter` configuration.

4. **Add a test folder** at `apps/mobile/test/features/<feature>/` with at least one test for the domain layer.

5. **Verify:**
   - `dart analyze`
   - `flutter test`

Follow the conventions in `apps/mobile/CLAUDE.md`: keep widgets small, prefer `const`, no business logic in widgets, Riverpod for state.
