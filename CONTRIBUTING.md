# Contributing

Describe the user-visible problem and expected behavior. For interface bugs, include the app/Windows version, theme, language and display scaling. Prefer synthetic audio samples; remove private paths, databases and credentials from reports.

## Setup

Use the SDK in `.flutter-version`, Visual Studio's Desktop development with C++ workload, and FFmpeg on `PATH` or in `tools/ffmpeg.exe`.

```powershell
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
flutter build windows --release --no-pub
```

Tests include real FFmpeg processing. Running without FFmpeg is not a complete check. No signing credentials or personal media are needed.

For schema or localization changes:

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

Keep generated files in sync. The Dart package is `toneharbor`. Existing database names, preference keys, Windows storage identifiers and matching platform-channel names are compatibility interfaces; changing them requires a migration.

## Interface and performance

Check all five themes, English/Arabic/Persian, 900×650 windows, ultrawide displays and Windows scaling. Preserve fixed row hit targets during selection and playback transitions. Use bounded caches and targeted playback-clock rebuilds.

Optional Windows widget previews use the system Segoe UI font and Flutter's bundled Material icons:

```powershell
flutter test --no-pub --dart-define=HARBOR_PREVIEW=true --dart-define=HARBOR_MEMORY_PROFILE=true
```

Previews go to ignored `output/`. They are widget renders, not live Windows captures.

Keep pull requests focused. Explain the change, validation, limitations and any migration or dependency-license changes. Add meaningful regression tests for storage, cancellation, playback identity, deletion or resource lifecycle changes.

By contributing, you agree to license your contribution under MIT and confirm you have the right to submit the code/assets.
