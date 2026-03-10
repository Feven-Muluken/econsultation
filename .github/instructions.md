# Instructions for econsultation

## Project shape
- Flutter app organized by **core + features**:
  - `lib/core`: cross-cutting models, services, storage, navigation, theme.
  - `lib/features`: screen-level UI grouped by domain (`auth`, `home`, `regulations`, `feedback`, `settings`).
- Entrypoint is `lib/main.dart` using `MaterialApp.router` + `AppRouter.router` (`lib/core/navigation/router.dart`).

## Architecture and data flow
- Authentication and profile flow:
  1. `LoginScreen` calls `ApiService.login` + `ApiService.logintoGetID`.
  2. Token/userId are persisted via `SecureStorage` (`auth_token`, `user_id`).
  3. Profile snapshots are cached in `AccountProfileStorage` and merged with backend profile on load.
- Regulations flow:
  - List pages use `DraftApi.fetchDraftRegulations`.
  - Detail page (`RegulationDetailScreen`) maps `DraftDetail` + `DraftSection` into the shared `Regulation` UI model.
  - Comments are posted through `DraftApi.postSectionComment`.
- News flow uses `NewsApi`/`MockContentApi`; fallback-to-mock is common when backend shape/errors vary.

## Service conventions (important)
- Services are singleton-style (`ApiService.instance`, `DraftApi.instance`, `NewsApi.instance`, `MockContentApi.instance`).
- Backend payloads are inconsistent; existing code intentionally normalizes multiple key variants.
  - Preserve this pattern when adding fields/endpoints (see `Regulation.fromJson`, `SectionComment.fromJson`, `ApiService.extractuserId`).
- `API_BASE_URL` is loaded from `.env` at startup; default fallback is `https://backend.e-consultation.gov.et`.
- Auth headers are added manually per service; do not assume a shared interceptor.

## UI/state conventions
- Most screens are `StatefulWidget` + local `setState`; Riverpod is a dependency but currently not used in active screens.
- Navigation uses `context.go(...)` with string paths from `AppRouter`; keep route names consistent (`/`, `/home`, `/documents`, `/documents/:id`, etc.).
- Styling should use `AppTheme` tokens from `lib/core/theme.dart` (colors, text styles, gradients) instead of introducing new ad-hoc values.
- Bottom tab behavior is centralized through `BottomNavBar` and route switching callbacks.

## Localization and generated code
- ARB files live in `lib/l10n/app_en.arb` and `lib/l10n/app_am.arb`.
- `lib/l10n/app_localizations*.dart` are generated; prefer editing ARB, then regenerating.
- There is also a custom localization helper at `lib/core/localization.dart`; check actual usage before expanding localization work.

## Storage and offline behavior
- Persistent local data uses `flutter_secure_storage` wrappers in `lib/core/storage`:
  - `SecureStorage` (token/user id)
  - `BookmarkStorage` (comma-separated IDs)
  - `FeedbackStorage` (JSON array)
  - `AccountProfileStorage` (active user + profile maps)
- When backend calls fail, UI often falls back to stored profile or mock content rather than hard-failing.

## Developer workflows
- Install deps: `flutter pub get`
- Run app: `flutter run`
- Static analysis: `flutter analyze`
- Tests: `flutter test` (current `test/widget_test.dart` is template-era and may not reflect current routed UI)
- Regenerate localizations after ARB changes: `flutter gen-l10n`
- Rebuild splash assets when changed: `dart run flutter_native_splash:create`
- Rebuild launcher icons when changed: `dart run flutter_launcher_icons`

## Known integration gotchas
- `.env` must exist (loaded in `main()` before `runApp`).
- `MockContentApi` references `assets/mock/regulations.json`; ensure asset exists if relying on mock regulations.
- Auth redirect logic in router is currently commented out; screens enforce auth checks ad hoc (for example `SettingsScreen`/`MyAccountScreen`).
