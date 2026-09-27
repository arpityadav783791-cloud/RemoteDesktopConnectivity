# Linux RDP Client

## Project status

This project is a Flutter-based Linux remote desktop client in active development. The current codebase includes a working app shell, GetX-based navigation, connection management, local storage, and a Linux RDP launcher that attempts to connect using `xfreerdp`.

The project is not a complete production-ready RDP client yet, and several parts are still incomplete or only partially implemented.

## Tech stack

- Flutter
- Dart
- GetX for state management and routing
- GetStorage for persistent local storage
- Linux system process execution via `Process.start`
- FreeRDP (`xfreerdp`) command-line client

## Dependency summary

From `pubspec.yaml` the app currently uses:

- `flutter`
- `cupertino_icons`
- `get: ^4.7.3`
- `get_storage: ^2.1.1`
- `flutter_lints` for development linting

## Implemented features

### 1. App bootstrap and app structure

- The app starts in `lib/main.dart`.
- `main()` initializes Flutter bindings and `GetStorage` before launching the app.
- `GetMaterialApp` is configured with:
  - `debugShowCheckedModeBanner: false`
  - `title: 'Linux RDP Client'`
  - `initialRoute: '/'`
  - `theme: AppTheme.light`
  - `darkTheme: AppTheme.dark`
- Initial binding is registered through `InitialBinding`.

### 2. Routing

The app defines two screens:

- Home screen: `/`
- Connection screen: `/connection`

Implemented in:

- `lib/app/routes/app_routes.dart`
- `lib/app/routes/app_pages.dart`

The Home and Connection screen controllers are lazily registered using `Get.lazyPut`.

### 3. Theme

- A simple Material 3 light/dark theme exists in `lib/app/theme/app_theme.dart`.
- It currently only sets brightness and `useMaterial3: true`.
- No custom brand colors or advanced visual styling have been implemented yet.

### 4. Data model

The core connection model is defined in `lib/data/models/rdp_connection.dart`.

Fields currently included:

- `name`
- `host`
- `username`
- `password`
- `domain` (optional)
- `fullscreen`
- `clipboard`
- `audio`
- `width`
- `height`
- `favorite`

It includes:

- `toJson()`
- `fromJson()`

### 5. Storage layer

`lib/core/services/storage_service.dart` implements local persistence through `GetStorage`.

Current behavior:

- Reads saved connections from a key named `rdp_connections`
- Writes connection list as JSON-serializable map data
- Returns an empty list if no saved connections exist

### 6. Home screen

Implemented in:

- `lib/modules/home/home_view.dart`
- `lib/modules/home/home_controller.dart`

Current features in the home screen:

- App bar with title `Linux RDP Client`
- Search field for connection lookup
- Add Connection button
- List of saved remote desktop connections
- Connection cards with:
  - connection name
  - username and host
  - status text
  - connect/disconnect button
  - edit button
  - delete button
  - favorite toggle button
- Filtered list based on name, host, or username
- Favorite connections are sorted to appear first
- Status tracking per connection through `RdpStatus`

Current statuses supported:

- `disconnected`
- `connecting`
- `connected`
- `failed`

### 7. Connection add/edit form

Implemented in:

- `lib/modules/connection/connection_view.dart`
- `lib/modules/connection/connection_controller.dart`

This screen currently supports:

- Connection name
- Host/IP address
- Username
- Password
- Domain (optional)
- Fullscreen toggle
- Clipboard toggle
- Audio toggle
- Resolution selection (`1280x720`, `1366x768`, `1920x1080`)
- Save connection

Behavior:

- Required fields are validated before saving.
- Duplicate detection checks for the same host + username combination before creating a new saved connection.
- Editing an existing saved connection is supported by passing the connection through `Get.arguments` and returning the updated object via `Get.back(result: connection)`.

### 8. RDP connection launch logic

Implemented in:

- `lib/core/services/rdp_service.dart`

This service currently:

- manages the active FreeRDP process using `Process.start`
- checks whether a server is reachable before attempting a connection
- builds FreeRDP command arguments for:
  - host
  - username
  - password
  - certificate ignore
  - fullscreen or custom width/height
  - clipboard
  - audio
  - domain
- starts FreeRDP at `/usr/bin/xfreerdp`
- listens to STDOUT and STDERR
- attempts to detect when a connection is established by checking for framebuffer output strings
- updates status to `connected` when output indicates a successful RDP session
- handles disconnect by sending `SIGTERM` to the running process
- exposes a `status` stream and `currentStatus`
- maps some RDP errors to user-friendly strings using `RdpErrorMapper`

### 9. Error mapping

Implemented in:

- `lib/core/utils/rdp_error_mapper.dart`

The mapper currently recognizes errors such as:

- connection failed
- authentication failed
- logon failure
- expired password
- account locked
- account restricted
- transport failure
- DNS name not found

It returns a human-readable fallback message if no known pattern is found.

## Partially implemented or incomplete work

The following items are either not implemented or only partially implemented:

### 1. Settings screen

- The `lib/modules/settings/` directory exists but is empty.
- The settings button in the home screen is present but currently has `onPressed: () {}` and does nothing.
- No settings page, preferences storage, or application configuration flow exists yet.

### 2. Real Linux desktop session handling

- The app launches `xfreerdp`, but there is no deeper desktop session integration beyond spawning the process and monitoring basic status.
- There is no explicit handling for multi-monitor layouts, secure credential storage, or advanced remote session configuration.

### 3. App polish and UX completeness

- The project does not yet include a final polished UI theme.
- No comprehensive icon set, custom fonts, or branded styling has been added.
- The app uses the default Material 3 design without custom visual identity.

### 4. Test coverage

- The project includes the default Flutter widget smoke test in `test/widget_test.dart`.
- This test is not specific to the RDP client and checks the default counter example behavior, not real app functionality.
- No project-specific RDP tests are present.

### 5. Code quality warnings

A fresh `flutter analyze` run shows the following warnings:

- 4 `avoid_print` info-level warnings in `lib/core/services/rdp_service.dart`
- No hard errors were reported in the current analyze run

These warnings indicate debug logging is still present in production code and should be replaced with a more suitable logging approach later.

## Current known implementation reality

At this point, the project includes:

- app shell and navigation
- saved connection data model
- storage persistence
- home page UI and connection management
- RDP connection launching through FreeRDP on Linux
- connection status tracking and basic error mapping

What is still missing or unfinished:

- settings functionality
- complete app-wide polish
- dedicated real app tests
- deeper remote desktop feature completeness
- cleanup of debug `print` statements

## Current project structure

```text
lib/
  app/
    bindings/
    routes/
    theme/
  core/
    services/
    utils/
  data/
    models/
    repositories/
  modules/
    connection/
    home/
    settings/
  main.dart

test/
  widget_test.dart
```

## Verification status

The current project was checked with:

```bash
flutter analyze
```

Result:

- analyzer completed successfully
- 4 info-level warnings detected
- no blocking errors reported at the moment

## Summary

This codebase is a working starting point for a Linux RDP client with a usable connection list and launch flow, but it is still under active development and not yet a full-featured final application.
