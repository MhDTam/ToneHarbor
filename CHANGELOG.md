# Changelog

## 1.1.4 — Windows portable release

- Added a downloadable Windows x64 portable package with license notices and SHA-256 verification.
- Replaced the gallery with seven captures from the running app, including Arabic.
- Documented separate FFmpeg and Microsoft Visual C++ runtime requirements.
- Restricted cache cleanup to ToneHarbor's own directory; startup retains fresh cache files.
- Fixed preview cancellation while the editor's temporary directory is still being prepared.

## Source preparation — 2026-10-28

- Added MIT licensing, dependency notices, clean source export and Windows CI.
- Added English/Arabic project pages and a six-image interface gallery.
- Bounded FLAC encoder frame sizes for normalized/spatial exports on newer FFmpeg builds.
- Added build instructions and contribution guidelines.
- Renamed the Dart package/application classes to ToneHarbor; retained stable storage identifiers for installed user profiles.

## Current desktop features

- Themed scrollbars, compact track menus and dismissible desktop notices.
- Distinct Home, Library, playlists, folders and settings workspaces.
- Full/mini players, real bounded waveforms, themes and editable shortcuts.
- Batch conversion, audio editing, independent preview and undo/redo.
- Windows Open with and single-instance activation.
- Bounded artwork caches, isolated playback-clock rebuilds and safe metadata-reader cleanup.

Application version remains the version in `pubspec.yaml`; local design iteration numbers are not semantic application versions.
