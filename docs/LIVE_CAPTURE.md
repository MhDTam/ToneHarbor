# Capturing the running application

The gallery is captured from a real Windows release process using `tool/capture_live.dart`. It starts the production application through the optional root wrapper, uses native playback and FFmpeg, and exports the live Flutter window content through a repaint boundary.

The development entry point redirects actual disk-backed preferences and Isar directories into an isolated capture directory. It requires `USERPROFILE` to match that directory, so normal Music/Downloads scanning cannot read a user's library. It does not override playback, song repositories or waveform providers with mocks. The normal `lib/main.dart` release has no capture boundary or capture automation.

Prepare at least six generated/demo MP3 files in `output/demo/media/`. Then:

```powershell
flutter pub get --enforce-lockfile
flutter build windows --release --target tool/capture_live.dart
$capture = (Resolve-Path output/demo).Path
Start-Process -FilePath build/windows/x64/runner/Release/ToneHarbor.exe -WorkingDirectory (Get-Location) -Environment @{ HARBOR_CAPTURE_ROOT = $capture; USERPROFILE = $capture }
```

This launch command requires PowerShell 7.4+ for per-process environment overrides. Close other app instances before capture. The helper writes seven PNGs and `capture.json` beneath the isolated directory, waits for the editor's actual waveform decode, then closes its window.

The native runner's normal Open with registration also runs for this development executable. Start your normal installed app afterwards to restore that executable's registration. Never distribute a binary built with the capture target.

Build public binaries with `tool/build_windows.ps1`, which explicitly targets `lib/main.dart`. Generated audio, databases and capture output stay in ignored `output/`; only reviewed PNGs belong in the gallery.
