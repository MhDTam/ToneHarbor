# Local source validation

Validated on Windows x64 on 2026-10-28, using Flutter 3.47.5, Dart 3.13.4 and the local FFmpeg 6.0 reference build.

- Exported a source-only copy into a separate directory, without the local design archive, build folders, app databases or FFmpeg executable.
- Resolved dependencies using the committed lockfile.
- Flutter analysis: no issues.
- Full test suite with optional preview and memory flags: **160 passed**.
- Built the native Windows release from that separate source copy.
- Ran the supplied portable-build script and verified its output includes project/dependency notices and Flutter's generated runtime notices, without bundling FFmpeg.
- Parsed all five GitHub YAML files and checked local documentation links.
- Collected license notices for 171 resolved SDK/runtime/development packages, with no missing top-level package notices in the inventory.
- Verified source-export guards reject an output outside the workspace and refuse to overwrite existing exports.

The logo test verifies its approved SHA-256 digest and 1254×1254 RGBA header without depending on a private design folder. Preview exporters create their own output directories.

GitHub Actions is configured for Windows analysis, tests and compilation. Check the repository Actions tab for remote results. This record describes local source validation; source publication is separate from binary releases and signing. Local test logs and source export manifests remain outside the repository.

Live runtime capture: the actual Windows app loaded eight generated MP3 files, populated real disk-backed playlists/preferences in an isolated directory, played and sought audio through just_audio_windows, decoded waveform data with FFmpeg, and exported seven 2250x1350 screenshots including Arabic. The editor capture waited for its complete real waveform before export. No personal library data was used.

Release validation on 2026-10-29: analysis reported no issues; all 158 tests passed, including application-scoped cache cleanup and cancellation before editor preview directory preparation completes. The full suite ran with two workers and a two-minute per-test timeout on the local machine.
