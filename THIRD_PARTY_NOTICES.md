# Third-party notices

The root MIT License applies to project-owned code, documentation and original artwork. Flutter, Dart packages, native plugins and external tools retain their own license terms.

## Flutter and Dart packages

Flutter's license is in `third_party/licenses/flutter-LICENSE.txt`. Package licenses are copied verbatim from resolved package roots into `third_party/licenses/packages/`; `third_party/dependencies.json` lists names, versions and notice filenames without local cache paths. The inventory includes development/transitive packages; it does not imply all listed packages ship in a binary.

Regenerate after lockfile changes:

```powershell
flutter pub get --enforce-lockfile
pwsh -File tool/collect_licenses.ps1
```

Flutter also emits runtime notices in `data/flutter_assets/NOTICES.Z`. Preserve that file and the project/dependency notices when distributing builds.

## FFmpeg

ToneHarbor invokes a separate FFmpeg executable. No FFmpeg binary is committed or included by the portable-build script. The local reference build reports `6.0-full_build-www.gyan.dev`, GPL version 3, source revision `ea3d24bbe3`. Its supplied license/configuration remain in `tools/FFmpeg-LICENSE.txt` and `tools/FFmpeg-BUILD-INFO.txt`. They describe that build, not every binary a user may install.

FFmpeg licensing depends on enabled components. When distributing an FFmpeg binary, preserve that exact build's notices, corresponding source and build information, including applicable external libraries. The application's MIT License does not replace those materials. See [FFmpeg licensing](https://ffmpeg.org/legal.html) and [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html).

## Artwork and fonts

The project owner authorized the included original artwork under MIT. Raster assets and theme variants are included as source assets. Live screenshots use generated demo audio in an isolated profile and do not grant rights to unrelated music or user-supplied artwork.

Segoe UI is a Windows system font and is not redistributed. Material icons come through Flutter and retain the SDK's notices. Existing file-specific copyright/license headers remain applicable.
