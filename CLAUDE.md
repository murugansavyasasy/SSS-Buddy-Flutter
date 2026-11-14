# CLAUDE.md

Guidance for Claude Code and developers working on **SSS Buddy** (`sssbuddy`), the Savyasasy field-sales / school-communication app (shown to users as "SSS Score").

## Toolchain

| Item | Value |
|---|---|
| Flutter | 3.44.0 (stable) |
| Dart | 3.12.0 (`environment.sdk: ^3.11.0`) |
| App version | `pubspec.yaml` → `version: 1.0.0+26` |
| Android | `applicationId`/`namespace` `com.sss.buddy`, Kotlin DSL (`android/app/build.gradle.kts`), Java/JVM 17, min/target/compile SDK from Flutter defaults |
| iOS | Bundle id `com.sss.buddy.sssbuddy`, deployment target 15.0, CocoaPods |

## Common commands

```bash
flutter pub get
flutter run                      # debug on the attached device/simulator
flutter analyze                  # currently ~370 info/warning issues, 0 errors — don't add new ones
flutter test                     # 10 tests, all passing
flutter test test/leaderboard_test.dart   # single file
flutter build apk --release      # uses android/key.properties if present, else debug signing
flutter build ipa
dart run flutter_launcher_icons  # regenerate icons from assets/images/logo.png
```

`build_runner` and `riverpod_generator` are in dev_dependencies, but **no code generation is used** (no `@riverpod`, no `part` files). Providers are written by hand.

## Project structure (`lib/`)

```
main.dart              App entry: portrait lock, LocalNotifications init, AppRoot (ProviderScope, restartable via UniqueKey)
auth/
  model/               Plain Dart model classes (fromJson / toJson), one file per API shape
  Menulists.dart       Role-based home menu builder + _hiddenMenuIds
components/            Shared app-wide widgets (cards, dropdowns, text fields, shimmer, dialogs, maps…)
core/
  network/DioClient.dart   Dio wrapper + ApiException
  storage/secure_storage.dart  flutter_secure_storage wrapper (static methods)
  aws/                 S3 upload response model + key constant
  chat/                ChatService (in-memory demo mode) + notifications
  followup/            Follow-up reminders
  location/            Trip GPS track store, road routing, map style
  notifications/       flutter_local_notifications wrapper (singleton)
provider/
  app_providers.dart   dioProvider, repositoryProvider, shared StateProviders
  user_session_provider.dart  UserSession AsyncNotifier backed by secure storage
repository/
  app_url.dart         Base URLs (VIMS, School, AWS)
  app_endpoint.dart    All endpoint paths as static constants / builder functions
  clientrepository.dart    Main repository for most features (~900 lines)
  exhibition_repository.dart, followup_repository.dart, leaderboard_repository.dart  Per-module repositories
utils/
  routes/routes.dart, routes_name.dart   Named-route table (onGenerateRoute)
  network_utils.dart   ConnectivityWrapper (wraps every page via MaterialApp.builder)
  app_logger.dart      AppLogger (logger package)
values/
  colors/app_colors.dart   AppColors
  Strings/strings_value.dart  Strings constants
view/                  Screens. Flat files for older features; feature folders with widget/ subfolders for newer ones
  exhibition/ chat/ followup/ leaderboard/ school_detail/ Alert/ Circular/ ManagementInfo/ RecordVoice/ UsageCount/
viewModel/             Riverpod notifiers / providers, one file per screen or feature
test/                  Unit + widget tests
docs/ROOT_TRACKER_API.md   Backend contract for trip GPS tracking
```

## Architecture: MVVM with Riverpod

Flow: **View (Consumer widget) → ViewModel (Riverpod notifier/provider) → Repository → DioClient → API**, with models in `auth/model/`.

### Riverpod (flutter_riverpod 3.x, manual providers)

- **Dominant pattern:** `class XViewModel extends AsyncNotifier<T>` with `build()` loading data, plus methods that set `state = const AsyncLoading()` / `AsyncData(...)` / `AsyncError(e, st)`. Exposed as a top-level `final xProvider = AsyncNotifierProvider<XViewModel, T>(() => XViewModel());` in the same file. (~40 of these.)
- **Newer modules** (Exhibitions, Leaderboard, Follow-ups) also use `FutureProvider.autoDispose` / `.family` for read-only data and invalidate them to refresh (see `refreshExhibition()` in `viewModel/exhibition_viewmodel.dart`). Exhibitions disables automatic retry with `retry: _noRetry` so failures show a Retry state.
- A few `Notifier`, `StreamProvider`, one `StateNotifier`; `StateProvider` comes from `package:flutter_riverpod/legacy.dart`.
- Repositories are obtained with `ref.read(repositoryProvider)` (or a module provider like `exhibitionRepositoryProvider`).
- Screens are `ConsumerWidget` / `ConsumerStatefulWidget`, using `ref.watch(provider).when(data:, loading:, error:)`.
- Logged-in user data is read from `ref.read(loginProvider).value` (`LoginData`) or `userSessionProvider`.
- `AppRoot.restartApp(context)` rebuilds the whole `ProviderScope` (used to reset state, e.g. on logout).

### Networking (Dio)

`core/network/DioClient.dart` builds four Dio instances, all with 30 s timeouts and `LogInterceptor`:

| Getter / methods | Base URL | Notes |
|---|---|---|
| `dio`, `get()`, `post()` | `AppUrl.vimsUrl` | `post()` adds `Authorization: Bearer <token>`; `get()` does not add it automatically |
| `schoolDio`, `schoolget()`, `schoolPost()` | `AppUrl.schoolUrl` | |
| `awsDio`, `awsGet()` | `AppUrl.aws_url` | e.g. presigned-URL request |
| `s3Dio`, `s3Put()` | none | PUT bytes to an S3 presigned URL |

- An error interceptor converts every `DioException` into `ApiException(message, statusCode)`, extracting a backend message from `message`/`Message`/`error`/`Error`/`errors`, else a friendly per-status/per-type message. Show `e.toString()` / `e.message` directly to users.
- The token comes from `DioClient.getToken()` → `loginProvider`.
- Endpoints live in `AppEndpoint`; never hard-code paths in repositories.
- `ExhibitionRepository` is the cleaner reference pattern: `_options()` adds the bearer header, `_guard()` unwraps `ApiException`, `_ensureOk()` treats `status: error/failed` or `success: false` bodies as errors.
- The plain `http` package is still used in a few places (`po_preview_viewmodel`, `today_visit_viewmodal`, `road_route_service`, `OverallTripDetailsModel`). Use Dio via repositories for new code.

### Models

Hand-written classes in `auth/model/`: `final` fields, named required constructor, `factory X.fromJson(Map<String, dynamic>)` with `??` defaults, `toJson()`. JSON keys match the backend exactly (often PascalCase, e.g. `"SchoolName"`). No json_serializable/freezed.

## Authentication & storage

- **Startup:** `Splash` watches `authProvider` (version check, `ClientRepository.getVersionCheckDetails`, hard-coded `VersionID`). Force update → blocking dialog; otherwise `LoginViewModel.restoreSession()` re-logs in with stored credentials, else goes to login.
- **Login:** `LoginViewModel.login()` → `ClientRepository.apilogin()` (`api/mobile/login`) → on `status == "success"` saves employeeId, password and full login JSON via `SecureStorage.saveLoginData`, refreshes `userSessionProvider`, sets global `globalUserId`.
- **SecureStorage** (static helpers): login data and trip start state. `clearLoginData()` calls `deleteAll()`.
- **SharedPreferences** is used for non-sensitive local data: follow-ups (`LocalFollowUpRepository`), trip GPS queue (`trip_track_store`), UI prefs (exhibition split view).
- Forgot/reset password via OTP: `otp_screen.dart`, `reset_password_screen.dart`.
- **Role-based menus:** `getMenuItems(vimsUserType: roleName, schoolUserType: roleCode)` in `auth/Menulists.dart`. To hide a menu without deleting its screen, add its id to `_hiddenMenuIds` (Chat 20, Follow-ups 21, Leaderboard 22 are currently hidden).

## Navigation

Named routes only: add a constant to `RoutesName` and a `case` in `Routes.generateRoutes` (pass arguments via `settings.arguments`). `appNavigatorKey` is the global navigator key. Some feature screens (e.g. inside Exhibitions) push `MaterialPageRoute`s directly.

## UI components

- **App-wide:** `lib/components/` (`AppCard`, `CustomButton`, `CustomTextField`, `CustomDropdown`, `searchable_dropdown`, `EmptyState`, `ShimmerBox`, `StatusBadge`, `common_dialog`, `header_toolbar`, `TripRouteMap`, `TripTimelineView`, …). Check here before writing a new widget. Colors: `AppColors`; strings: `Strings`.
- **Exhibitions design kit:** `view/exhibition/widget/exhibition_common.dart` is a self-contained design system for that module: DM Sans font (`exFont`, bundled in `assets/Fonts/DMSans`), color tokens (`exInk`, `exBrand`, `exSubtle`, `exPageBg`, `exBorder`, …), type scale (`exHeadingXl/Lg/Md/Sm`), breakpoints (`exIsWide`, `exIsSplit`, `exIsPhone`) and widgets (`ExTheme`, `ExPage`, `ExCard`, `ExField`, `ExPrimaryButton`, `ExStateView`, `ExSkeletonList`, `ExStatusBadge`, …). Use these inside Exhibitions and don't mix them with `AppColors`.
- Feature folders keep their own `widget/` subfolder with a `*_common.dart` for shared styling (chat, followup, leaderboard).
- Exhibitions supports an iPad split view.

## Feature notes

- **Chat** (`core/chat/chat_service.dart`) runs in local demo mode with in-memory data; no backend yet.
- **Follow-ups** use device-only storage (`LocalFollowUpRepository`) behind the abstract `FollowUpRepository`.
- **Leaderboard** uses `DemoLeaderboardRepository` (sample data) behind `LeaderboardRepository`.
- **Voice recording/upload:** `record` + `just_audio`; upload = get presigned URL (`awsGet`) → `s3Put`.
- **Trip tracking / Today Visit / Root Tracker:** `geolocator`, `flutter_map` + `vector_map_tiles`; backend contract in `docs/ROOT_TRACKER_API.md`.
- **Excel export:** `view/TripExcelExporter.dart` (`excel` + `path_provider` + `share_plus`).

## Platform configuration

- **Android permissions:** INTERNET, fine/coarse location, FOREGROUND_SERVICE(_LOCATION), CAMERA, RECORD_AUDIO, READ_EXTERNAL_STORAGE, POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, WAKE_LOCK. Release signing reads `android/key.properties` (not committed).
- **iOS Info.plist:** camera, photo library, location (when-in-use and always), microphone, contacts usage strings; `UIBackgroundModes` set. New permission-using features need both manifest and plist entries.
- The app locks to portrait in `main.dart`.

## Testing

- Tests in `test/`: `followup_repository_test` (SharedPreferences mocked with `setMockInitialValues`), `leaderboard_test` (ranking logic + widget overflow test in a `ProviderScope`), `route_stops_test`, `track_point_test` (pure model/logic tests). `widget_test.dart` is an empty placeholder.
- No mocking library: tests build models directly or use in-memory/demo repositories.
- Prefer testing pure logic (models, ranking, parsing) and repository round-trips; add tests next to these when changing that logic.

## Conventions & guidelines for new work

- Follow MVVM: UI only in `view/`, state and logic in `viewModel/`, HTTP only in a repository, endpoints only in `AppEndpoint`, models in `auth/model/`.
- New feature module: `view/<feature>/` + `view/<feature>/widget/`, `viewModel/<feature>_viewmodel.dart`, optional `repository/<feature>_repository.dart` with its provider, model in `auth/model/`, route in `routes.dart` + `routes_name.dart`, menu entry in `Menulists.dart`.
- Use `package:sssbuddy/...` or relative imports, whichever the surrounding file uses. Note that `routes.dart` imports `package:sssbuddy/View/...` (capital V) while the folder is `view/`; this only works on case-insensitive filesystems (macOS/Windows).
- File naming is mixed (PascalCase models like `ExhibitionModel.dart`, snake_case views/viewmodels, some misspellings like `viewmodal`). Match the neighbours rather than renaming existing files.
- Surface errors with `ApiException` messages; show an error state with a retry rather than an endless loader.
- Prefer `AppLogger` over `print` in new code (older code still has `print`).
- Don't commit secrets. Base URLs live in `AppUrl` and the AWS constant in `core/aws/aws_key.dart`.
- Keep `flutter analyze` from gaining new warnings, and run `flutter test` before committing.
- Git: day-to-day work happens on the `Development` branch; `main` is the PR target. Commit messages use a `Module: change summary` style (e.g. `Exhibitions: …`).
